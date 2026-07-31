import haxefolio.browser.ActivityTracker;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import haxefolio.LocaleUtils;
import haxefolio.menu.MenuAction;
import haxefolio.menu.MenuBarItem;
import haxefolio.menu.MenuFacade;
import client.auth.Session;
import net.models.auth.AuthCredentials;
import client.ui.home.HomePage;
import client.ui.analysis.AnalysisPage;
import client.ui.game.LiveGamePage;
import client.ui.profile.ProfilePage;
import client.ui.challenge.ChallengeJoiningPage;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;

class Main
{
    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setDebounceMs(100)
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("analysis", params -> new AnalysisPage())
            .addPage("study/{id}", params -> new AnalysisPage(Std.parseInt(params.get("id"))))
            .addPage("live/{gameID}", params -> new LiveGamePage(Std.parseInt(params.get("gameID"))))
            .addPage("player/{login}", params -> new ProfilePage(params.get("login")))
            .addPage("join/{id}", params -> new ChallengeJoiningPage(Std.parseInt(params.get("id"))))
            .addLeftMenubarItem(NormalMenu("play", []))
            .addNormalMenuItem("play", "create_game", Execute(onCreateGamePressed), "assets/images/menubar/menu_items/new_game.svg")
            .addNormalMenuItem("play", "open_challenges", NavigateTo(() -> "home"), "assets/images/menubar/menu_items/open_challenges.svg")
            .addNormalMenuItem("play", "versus_bot", Execute(onVersusBotPressed), "assets/images/menubar/menu_items/versus_bot.svg")
            .addLeftMenubarItem(NormalMenu("watch", []))
            .addNormalMenuItem("watch", "current_games", NavigateTo(() -> "home"), "assets/images/menubar/menu_items/current_games.svg")
            .addNormalMenuItem("watch", "watch_player", Execute(onWatchPlayerPressed), "assets/images/menubar/menu_items/watch_player.svg")
            .addLeftMenubarItem(NormalMenu("learn", []))
            .addNormalMenuItem("learn", "analysis_board", NavigateTo(() -> "analysis"), "assets/images/menubar/menu_items/analysis_board.svg")
            .addLeftMenubarItem(NormalMenu("social", []))
            .addNormalMenuItem("social", "player_profile", Execute(onPlayerProfilePressed), "assets/images/menubar/menu_items/player_profile.svg")
            .addNormalMenuItem("social", "vk", Link("https://vk.com/intellectorgroup", true), "assets/images/menubar/menu_items/vk.svg")
            .addNormalMenuItem("social", "discord", Link("https://discord.gg/f8chehcnV5", true), "assets/images/menubar/menu_items/discord.svg")
            .addNormalMenuItem("social", "iteration", Link("https://t.me/iteracia_club", true), "assets/images/menubar/menu_items/iteration.svg")
            .addRightMenubarItem(NormalMenu("account", []))
            .addNormalMenuItem("account", "my_profile", NavigateTo(() -> "player/" + Session.currentLogin), "assets/images/menubar/account/my_profile.svg", null, true)
            .addNormalMenuItem("account", "preferences", Execute(HaxeFolioApp.showPreferences), "assets/images/menubar/account/settings.svg")
            .addNormalMenuItem("account", "log_in_out", Execute(() -> {}), "assets/images/menubar/account/log_in.svg")
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
        ActivityTracker.activate();

        Rest.init(Session.currentToken);
        PubSub.start(Session.currentToken, ActivityTracker.getLastActivityTs);
        bootstrapSession(refreshAccountMenu);
        Session.onSessionChanged(refreshAccountMenu);
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

    /*
        Silent-reauth chain run once at startup: stored token -> remembered credentials -> guest.
        Every failure branch (a real 401 or a network/server error) is treated identically - "this
        step didn't work, try the next one" - see knowledge/login_plan.md for the reasoning.
    */
    private static function bootstrapSession(onReady:Void->Void):Void
    {
        var token:Null<String> = Session.currentToken();
        if (token != null)
        {
            Rest.client().execute(RestOperationRegistry.WHOAMI, response -> {
                if (response.guest_id != null)
                    Session.recordGuest(token, response.guest_id);
                else
                    Session.recordIdentity(token, response);
                onReady();
            }, error -> {
                Session.forgetToken();
                signInWithRememberedCredentialsOrGuest(onReady);
            });
            return;
        }

        signInWithRememberedCredentialsOrGuest(onReady);
    }

    private static function signInWithRememberedCredentialsOrGuest(onReady:Void->Void):Void
    {
        var credentials:Null<{login:String, password:String}> = Session.rememberedCredentials();
        if (credentials != null)
        {
            Rest.client().execute(RestOperationRegistry.SIGN_IN, response -> {
                Session.recordIdentity(response.token, response.identity);
                onReady();
            }, error -> {
                Session.forgetCredentials();
                authAsGuest(onReady);
            }, null, null, ({login: credentials.login, password: credentials.password} : AuthCredentials));
            return;
        }

        authAsGuest(onReady);
    }

    private static function authAsGuest(onReady:Void->Void):Void
    {
        Rest.client().execute(RestOperationRegistry.AUTH_AS_GUEST, response -> {
            Session.recordGuest(response.token, response.guest_id);
            onReady();
        }, error -> onReady());
    }

    private static function refreshAccountMenu():Void
    {
        MenuFacade.updateMenuLabelText("account", Session.currentNickname ?? LocaleUtils.localeBinding("intellector.common.player.guest_generic"));

        if (Session.isGuest())
            MenuFacade.hideMenuItem("account", "my_profile");
        else
            MenuFacade.showMenuItem("account", "my_profile");
    }
}
