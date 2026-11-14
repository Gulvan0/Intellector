import client.ServerTime;
import client.update.ApiMismatch;
import client.update.UpdateWatcher;
import client.auth.AuthBootstrap;
import client.ui.Assets;
import client.ui.BoardLayoutTier;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.storage.LocalStorageKey;
import client.migration.ChallengeDraftMigration;
import client.migration.CredentialsMigration;
import client.migration.LegacyUrlMigration;
import client.migration.PreferenceMigration;
import client.logic.challenge.creation.ChallengePrefills;
import client.ui.common.overlays.challenge.ChallengeCreationLauncher;
import client.ui.common.overlays.login.LoginOverlay;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import haxefolio.browser.ActivityTracker;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import client.ui.home.HomeLayoutTier;
import client.ui.home.HomePage;
import client.ui.analysis.AnalysisPage;
import client.ui.changelog.ChangelogPage;
import client.ui.games.GamesLayoutTier;
import client.ui.games.GamesPage;
import client.ui.game.LiveGamePage;
import client.ui.profile.ProfileLayoutTier;
import client.ui.profile.ProfilePage;
import client.ui.challenge.ChallengeJoiningPage;
import client.tabs.GameRedirect;
import client.datatypes.game.StartedGame;
import client.utils.AssetPreloader;
import client.watch.WatchKeeper;
import client.ui.StyleVars;
import client.ui.common.account.AccountWidget;
import client.ui.common.challenges.widget.ChallengesWidget;
import client.ui.common.games.widget.OngoingGamesWidget;
import client.ui.common.notifications.ConnectionNotice;
import client.ui.common.notifications.GameStartedNotice;
import client.ui.common.notifications.InfoNotice;
import client.ui.common.watch.widget.WatchWidget;
import haxe.ui.core.Component;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.Everyone;
import net.ws.events.ServerShutdown;
import client.build.BuildInfo;
import client.errors.ErrorReporter;
import client.ui.common.challenges.ChallengeFlows;
import client.ui.common.games.OngoingGamesFeed;
import client.ui.common.overlays.challenge.ChallengeCreationFlow;
import client.ui.common.watch.WatchFlows;
import client.ui.game.controllers.BotGameRequests;
import js.html.Location;
import net.models.other.ClientErrorReport;

class Main
{
    /** Shorter than the server's away threshold, so that a resumed user never stays "away" until the next scheduled heartbeat **/
    private static inline final IDLE_THRESHOLD_SECS:Int = 60;

    private static inline final MAX_REPORTED_PATH_LENGTH:Int = 512;

    private static var challengesWidget:ChallengesWidget;
    private static var ongoingGamesWidget:OngoingGamesWidget;
    private static var accountWidget:AccountWidget;
    private static var watchWidget:WatchWidget;

    public static function main():Void
    {
        var tokenRetriever:Void->Null<String> = () -> HaxeFolioApp.valueStorage?.read(LocalStorageKey.TOKEN);
        Rest.init(tokenRetriever);
        Rest.client().onDeserializationFailed = ErrorReporter.report;
        ErrorReporter.start(sendErrorReport);

        LegacyUrlMigration.run();

        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setLeaveConfirmText("{{intellector.common.leave_confirm}}")
            .setPageFailureHandler(ErrorReporter.report)
            .setDebounceMs(100)
            .setMenuRailHeight(BoardLayoutTier.RAIL_MAX_HEIGHT)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Compact, 0)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Rail, BoardLayoutTier.RAIL_MIN_WIDTH, BoardLayoutTier.fitsRailTier)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Medium, BoardLayoutTier.MEDIUM_MIN_WIDTH, BoardLayoutTier.fitsMedium)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Wide, BoardLayoutTier.WIDE_MIN_WIDTH, BoardLayoutTier.fitsWide)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Narrow, 0)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Medium, ProfileLayoutTier.MEDIUM_MIN_WIDTH)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Wide, ProfileLayoutTier.WIDE_MIN_WIDTH)
            .addWidthTier(HomeLayoutTier.SCALE, HomeLayoutTier.Narrow, 0)
            .addWidthTier(HomeLayoutTier.SCALE, HomeLayoutTier.Wide, HomeLayoutTier.WIDE_MIN_WIDTH)
            .addWidthTier(GamesLayoutTier.SCALE, GamesLayoutTier.Narrow, 0)
            .addWidthTier(GamesLayoutTier.SCALE, GamesLayoutTier.Wide, GamesLayoutTier.WIDE_MIN_WIDTH)
            .setAppearance({selectionEmphasis: Outlined, geometry: {fieldHeight: {expanded: 37, collapsed: 44}}, shadows: StyleVars.HAXEFOLIO_SHADOWS}) // outlined: brass shares the board's hue family
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("analysis", params -> new AnalysisPage())
            .addPage("analyze/{gameID}/{plyCount}", params -> new AnalysisPage(null, {gameId: Std.parseInt(params.get("gameID")), plyCount: Std.parseInt(params.get("plyCount"))}))
            .addPage("study/{id}", params -> new AnalysisPage(Std.parseInt(params.get("id"))))
            .addPage("live/{gameID}", params -> new LiveGamePage(Std.parseInt(params.get("gameID"))))
            .addPage("player/{login}", params -> new ProfilePage(params.get("login")))
            .addPage("join/{id}", params -> new ChallengeJoiningPage(Std.parseInt(params.get("id"))))
            .addPage("changelog", params -> new ChangelogPage())
            .addPage("games", params -> new GamesPage())
            .setMenubarChevronsShown(false)
            .addLeftMenubarItem(NormalMenu("play", []))
            .addNormalMenuItem("play", "create_game", Execute(onCreateGamePressed), Assets.menuItemIcon("new_game"))
            .addNormalMenuItem("play", "open_challenges", NavigateTo(() -> "home"), Assets.menuItemIcon("open_challenges"))
            .addNormalMenuItem("play", "versus_bot", Execute(onVersusBotPressed), Assets.menuItemIcon("versus_bot"))
            .addLeftMenubarItem(NormalMenu("watch", []))
            .addNormalMenuItem("watch", "current_games", NavigateTo(() -> "home"), Assets.menuItemIcon("current_games"))
            .addNormalMenuItem("watch", "watch_player", Execute(WatchFlows.presentPlayerSearch), Assets.menuItemIcon("watch_player"))
            .addLeftMenubarItem(NormalMenu("learn", []))
            .addNormalMenuItem("learn", "analysis_board", NavigateTo(() -> "analysis"), Assets.menuItemIcon("analysis_board"))
            .addLeftMenubarItem(NormalMenu("social", []))
            .addNormalMenuItem("social", "player_profile", Execute(onPlayerProfilePressed), Assets.menuItemIcon("player_profile"))
            .addNormalMenuItem("social", "vk", Link("https://vk.com/intellectorgroup", true), Assets.menuItemIcon("vk"))
            .addNormalMenuItem("social", "discord", Link("https://discord.gg/f8chehcnV5", true), Assets.menuItemIcon("discord"))
            .addNormalMenuItem("social", "iteration", Link("https://t.me/iteracia_club", true), Assets.menuItemIcon("iteration"))
            .addRightMenubarItem(Widget(createWatchWidget, true))
            .addRightMenubarItem(Widget(createOngoingGamesWidget, true))
            .addRightMenubarItem(Widget(createChallengesWidget, true))
            .addRightMenubarItem(Widget(createAccountWidget, true))
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        // before the first page opens: it may load data right away
        ServerTime.init(Rest.serverClock().now);
        PubSub.start(tokenRetriever, () -> ActivityTracker.getLastActivityTs(), null, AuthBootstrap.run); // the token was rejected: revalidate it, falling back to the guest

        HaxeFolioApp.init(config);
        ConnectionNotice.init();
        PubSub.watchConnection(onConnectionOpened, ConnectionNotice.onDisconnected);
        PubSub.watchClose(ApiMismatch.onConnectionClosed);
        PubSub.watchMessageFailures(ErrorReporter.report);
        UpdateWatcher.init(() -> LiveGamePage.isShowingOwnOngoingGame() || !HaxeFolioApp.currentPageMayBeLeft() || HaxeFolioApp.overlayHoldsInput());
        js.Browser.window.addEventListener("online", PubSub.reconnectNow);
        js.Browser.document.addEventListener("visibilitychange", PubSub.sendHeartbeat); // a hidden tab's timers are throttled: tell the server the tab is alive before they are, and check the connection on return
        PubSub.listen(new Everyone()).onEventLight(ServerShutdown, _ -> InfoNotice.show("intellector.server_shutdown_notice.title", "intellector.server_shutdown_notice.text"));
        PreferenceMigration.run();
        ChallengeDraftMigration.run();
        CredentialsMigration.run();
        ActivityTracker.activate(IDLE_THRESHOLD_SECS, PubSub.sendHeartbeat);
        var challengeFlows:ChallengeFlows = new ChallengeFlows(challengesWidget);
        var ongoingGamesFeed:OngoingGamesFeed = new OngoingGamesFeed(ongoingGamesWidget);
        ongoingGamesWidget.currentGameId = () -> LiveGamePage.openGameId;
        GameRedirect.init(openStartedGame);
        var watchFlows:WatchFlows = new WatchFlows(watchWidget, {
            openGameId: () -> LiveGamePage.openGameId,
            isShowingOwnOngoingTimedGame: LiveGamePage.isShowingOwnOngoingTimedGame,
            isShowingOthersOngoingTimedGame: LiveGamePage.isShowingOthersOngoingTimedGame
        });
        watchWidget.currentGameId = () -> LiveGamePage.openGameId;
        BotGameRequests.connect();
        ChallengeCreationLauncher.launch = ChallengeCreationFlow.present;
        IdentityKeeper.init([_ -> PubSub.reauth(), refreshAccountMenu, challengeFlows.onIdentityChanged, ongoingGamesFeed.onIdentityChanged]);
        WatchKeeper.init([watchFlows.onWatchedChanged]);
        js.Browser.window.addEventListener("installpromptchange", refreshInstallItem);
        refreshInstallItem();
        AuthBootstrap.run();
        haxe.Timer.delay(AssetPreloader.start, 0);
    }

    private static function onConnectionOpened():Void
    {
        ConnectionNotice.onConnected();
        UpdateWatcher.check();
    }

    private static function onCreateGamePressed():Void
    {
        ChallengeCreationFlow.present();
    }

    private static function onVersusBotPressed():Void
    {
        ChallengeCreationFlow.present(ChallengePrefills.versusBot);
    }

    private static function onPlayerProfilePressed():Void
    {
        PlayerSearchOverlay.present(LocaleUtils.localeBinding("intellector.overlay.player_search.title.find_player"), false, player -> HaxeFolioApp.navigateTo('player/${player.login}'));
    }

    private static function refreshInstallItem():Void
    {
        accountWidget.dropdown.setItemHidden("fullscreen_app", Reflect.field(js.Browser.window, "deferredInstallPrompt") == null);
    }

    private static function onFullscreenAppPressed():Void
    {
        var installPrompt:Null<Dynamic> = Reflect.field(js.Browser.window, "deferredInstallPrompt");
        if (installPrompt == null)
            return;

        Reflect.setField(js.Browser.window, "deferredInstallPrompt", null);
        installPrompt.prompt();
        refreshInstallItem();
    }

    private static function refreshAccountMenu(newIdentity:Identity):Void
    {
        accountWidget.render(newIdentity);
        accountWidget.dropdown.setItemHidden("log_in", !newIdentity.isGuest());
        accountWidget.dropdown.setItemHidden("log_out", newIdentity.isGuest());
    }

    private static function createOngoingGamesWidget():Component
    {
        ongoingGamesWidget = new OngoingGamesWidget();
        return ongoingGamesWidget.dropdown;
    }

    private static function createAccountWidget():Component
    {
        accountWidget = new AccountWidget([
            {slug: "preferences", action: Execute(HaxeFolioApp.showPreferences), icon: Assets.menuItemIcon("settings")},
            {slug: "log_in", action: Execute(LoginOverlay.present), icon: Assets.menuItemIcon("log_in")},
            {slug: "fullscreen_app", action: Execute(onFullscreenAppPressed), icon: Assets.menuItemIcon("fullscreen_app"), hiddenByDefault: true},
            {slug: "log_out", action: Execute(AuthBootstrap.logOut), icon: Assets.menuItemIcon("log_out"), hiddenByDefault: true}
        ]);
        return accountWidget.dropdown;
    }

    private static function createWatchWidget():Component
    {
        watchWidget = new WatchWidget(WatchKeeper.watch, WatchKeeper.stop);
        return watchWidget.dropdown;
    }

    private static function createChallengesWidget():Component
    {
        challengesWidget = new ChallengesWidget();
        return challengesWidget.dropdown;
    }

    private static function openStartedGame(game:StartedGame):Void
    {
        if (LiveGamePage.isShowingOwnOngoingGame())
            GameStartedNotice.show(game);
        else
            HaxeFolioApp.navigateTo('live/${game.id}');
    }

    private static function sendErrorReport(message:String, stack:Null<String>):Void
    {
        var location:Location = js.Browser.location;
        var report:ClientErrorReport = {
            message: message,
            stack: stack,
            build_id: BuildInfo.BUILD_ID,
            page_path: (location.pathname + location.search).substr(0, MAX_REPORTED_PATH_LENGTH)
        };
        Rest.client().execute(RestOperationRegistry.REPORT_CLIENT_ERROR, _ -> {}, _ -> {}, null, null, report);
    }
}
