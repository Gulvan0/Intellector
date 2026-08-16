import client.auth.AuthBootstrap;
import client.Assets;
import client.formatters.IdentityFormatters;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.LocalStorageKey;
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
import net.rest.Rest;
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
            .addNormalMenuItem("account", "log_in", Execute(() -> HaxeFolioApp.showOverlay("login", dismiss -> new LoginOverlay(dismiss))), Assets.menuItemIcon("log_in"))
            .addNormalMenuItem("account", "log_out", Execute(() -> {}), Assets.menuItemIcon("log_out"), null, true)
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
        ActivityTracker.activate();

        var tokenRetriever:Void->Null<String> = HaxeFolioApp.valueStorage.read.bind(LocalStorageKey.TOKEN);
        Rest.init(tokenRetriever);
        PubSub.start(tokenRetriever, ActivityTracker.getLastActivityTs);
        IdentityKeeper.init([refreshAccountMenu]);
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
}
