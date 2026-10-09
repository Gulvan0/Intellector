import client.auth.AuthBootstrap;
import client.ui.Assets;
import client.formatters.IdentityFormatters;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.LocalStorageKey;
import client.PreferenceMigration;
import client.ui.common.overlays.login.LoginOverlay;
import haxefolio.browser.ActivityTracker;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import haxefolio.menu.MenuFacade;
import client.ui.home.HomePage;
import client.ui.analysis.AnalysisPage;
import client.ui.game.LiveGamePage;
import client.ui.profile.ProfilePage;
import client.ui.challenge.ChallengeJoiningPage;
import client.datatypes.IncomingChallenge;
import client.ui.StyleVars;
import client.ui.common.notifications.challenges.IncomingChallengesController;
import easypubsub.Subscription;
import net.models.challenge.mappers.IncomingChallengeMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.IncomingChallenges;
import net.ws.events.IncomingChallengeCancelled;
import net.ws.events.IncomingChallengeReceived;
import net.ws.events.IncomingChallengesCancelledByServer;
import net.ws.events.IncomingChallengesRefresh;

class Main
{
    private static var incomingChallenges:IncomingChallengesController;
    private static var incomingChallengesSubscription:Null<Subscription<IncomingChallenges>> = null;

    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setDebounceMs(100)
            .setAppearance({selectionEmphasis: Outlined, geometry: {fieldHeight: {expanded: 37, collapsed: 44}}, shadows: StyleVars.HAXEFOLIO_SHADOWS}) // outlined: brass shares the board's hue family (knowledge/intellector-style.md §5.1); field heights: §5.2/§5.4
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("analysis", params -> new AnalysisPage())
            .addPage("study/{id}", params -> new AnalysisPage(Std.parseInt(params.get("id"))))
            .addPage("live/{gameID}", params -> new LiveGamePage(Std.parseInt(params.get("gameID"))))
            .addPage("player/{login}", params -> new ProfilePage(params.get("login")))
            .addPage("join/{id}", params -> new ChallengeJoiningPage(Std.parseInt(params.get("id"))))
            .setMenubarChevronsShown(false)
            .addLeftMenubarItem(NormalMenu("play", []))
            .addNormalMenuItem("play", "create_game", Execute(onCreateGamePressed), Assets.menuItemIcon("new_game"))
            .addNormalMenuItem("play", "open_challenges", NavigateTo(() -> "home"), Assets.menuItemIcon("open_challenges"))
            .addNormalMenuItem("play", "versus_bot", Execute(onVersusBotPressed), Assets.menuItemIcon("versus_bot"))
            .addLeftMenubarItem(NormalMenu("watch", []))
            .addNormalMenuItem("watch", "current_games", NavigateTo(() -> "home"), Assets.menuItemIcon("current_games"))
            .addNormalMenuItem("watch", "watch_player", Execute(onWatchPlayerPressed), Assets.menuItemIcon("watch_player"))
            .addLeftMenubarItem(NormalMenu("learn", []))
            .addNormalMenuItem("learn", "analysis_board", NavigateTo(() -> "analysis"), Assets.menuItemIcon("analysis_board"))
            .addLeftMenubarItem(NormalMenu("social", []))
            .addNormalMenuItem("social", "player_profile", Execute(onPlayerProfilePressed), Assets.menuItemIcon("player_profile"))
            .addNormalMenuItem("social", "vk", Link("https://vk.com/intellectorgroup", true), Assets.menuItemIcon("vk"))
            .addNormalMenuItem("social", "discord", Link("https://discord.gg/f8chehcnV5", true), Assets.menuItemIcon("discord"))
            .addNormalMenuItem("social", "iteration", Link("https://t.me/iteracia_club", true), Assets.menuItemIcon("iteration"))
            .addRightMenubarItem(NormalMenu("account", []))
            .addNormalMenuItem("account", "my_profile", NavigateTo(getMyProfilePath), Assets.menuItemIcon("my_profile"), null, true)
            .addNormalMenuItem("account", "preferences", Execute(HaxeFolioApp.showPreferences), Assets.menuItemIcon("settings"))
            .addNormalMenuItem("account", "log_in", Execute(LoginOverlay.present), Assets.menuItemIcon("log_in"))
            .addNormalMenuItem("account", "log_out", Execute(AuthBootstrap.logOut), Assets.menuItemIcon("log_out"), null, true)
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
        PreferenceMigration.run();
        ActivityTracker.activate();

        var tokenRetriever:Void->Null<String> = HaxeFolioApp.valueStorage.read.bind(LocalStorageKey.TOKEN);
        Rest.init(tokenRetriever);
        PubSub.start(tokenRetriever, ActivityTracker.getLastActivityTs);
        incomingChallenges = new IncomingChallengesController(acceptChallenge, declineChallenge);
        IdentityKeeper.init([refreshAccountMenu, subscribeToIncomingChallenges]);
        AuthBootstrap.run();
    }

    /*
        Stub handlers for menu items that used to open a Dialogs.* popup (challenge params dialog
        or a plain login-input prompt) in the original iteration. No dialog/overlay equivalent
        exists yet - see knowledge/menu_deferred.md item 2.
    */
    private static function onCreateGamePressed():Void {}
    private static function onVersusBotPressed():Void {}
    private static function onWatchPlayerPressed():Void {}
    private static function onPlayerProfilePressed():Void {}

    private static function getMyProfilePath():String
    {
        var login:Null<String> = IdentityKeeper.currentIdentity.getLogin();
        return login != null? 'player/$login' : 'home';
    }

    private static function refreshAccountMenu(newIdentity:Identity):Void
    {
        MenuFacade.updateMenuLabelText("account", IdentityFormatters.formatRaw(newIdentity));
        MenuFacade.setMenuItemHidden("account", "my_profile", newIdentity.isGuest());
        MenuFacade.setMenuItemHidden("account", "log_in", !newIdentity.isGuest());
        MenuFacade.setMenuItemHidden("account", "log_out", newIdentity.isGuest());
    }

    private static function subscribeToIncomingChallenges(identity:Identity):Void
    {
        if (incomingChallengesSubscription != null)
        {
            incomingChallengesSubscription.detach();
            incomingChallengesSubscription = null;
        }

        incomingChallenges.reset();

        var userRef:Null<String> = switch identity {
            case Player(login, _): login;
            case Guest(guestId): guestId != null ? '_$guestId' : null;
        }

        if (userRef == null)
            return;

        incomingChallengesSubscription = PubSub.sub(new IncomingChallenges(userRef))
            .onEventLight(IncomingChallengesRefresh, refresh -> incomingChallenges.sync(refresh.challenges.map(IncomingChallengeMapper.dtoToDatatype)))
            .onEventLight(IncomingChallengeReceived, challenge -> incomingChallenges.announce(IncomingChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(IncomingChallengeCancelled, cancelled -> incomingChallenges.remove(cancelled.id))
            .onEventLight(IncomingChallengesCancelledByServer, cancelled -> {
                for (id in cancelled.ids)
                    incomingChallenges.remove(id);
            });
    }

    private static function acceptChallenge(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.ACCEPT_CHALLENGE,
            game -> {
                incomingChallenges.acceptSucceeded();
                HaxeFolioApp.navigateTo('live/${game.id}');
            },
            _ -> incomingChallenges.acceptFailed(challenge.id),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // already off display; a failed decline leaves the challenge pending, see knowledge/plans/challenge_notification_deferred.md
    private static function declineChallenge(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.DECLINE_CHALLENGE,
            _ -> {},
            _ -> {},
            ["challenge_id" => Std.string(challenge.id)]
        );
    }
}
