import client.ServerTime;
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
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengePrefills;
import client.ui.common.overlays.challenge.ChallengeCreationLauncher;
import client.ui.common.overlays.challenge.ChallengeCreationOverlay;
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
import client.ui.game.LiveGamePage;
import client.ui.profile.ProfileLayoutTier;
import client.ui.profile.ProfilePage;
import client.ui.challenge.ChallengeJoiningPage;
import client.storage.ChallengeMarksStorage;
import client.tabs.GameRedirect;
import client.tabs.WatchedGameClaim;
import client.datatypes.challenge.creation.ChallengeCreationOutcome;
import client.datatypes.challenge.ChallengeMarks;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.request.FailedAction;
import client.datatypes.challenge.IncomingChallenge;
import client.datatypes.challenge.OutgoingChallenge;
import client.datatypes.game.OngoingGame;
import client.datatypes.game.StartedGame;
import client.datatypes.player.FoundPlayer;
import client.datatypes.watch.WatchedGameReactionKind;
import client.datatypes.watch.WatchedPlayer;
import client.logic.watch.WatchedGameReaction;
import client.utils.PagePaths;
import client.utils.PlayerStatusFeed;
import client.watch.WatchKeeper;
import client.ui.StyleVars;
import client.ui.common.account.AccountWidget;
import client.ui.common.challenges.ChallengesController;
import client.ui.common.challenges.widget.ChallengesWidget;
import client.ui.common.games.OngoingGamesController;
import client.ui.common.games.widget.OngoingGamesWidget;
import client.ui.common.notifications.CalleeOfflineNotice;
import client.ui.common.notifications.ConnectionNotice;
import client.ui.common.notifications.GameStartedNotice;
import client.ui.common.notifications.InfoNotice;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.common.notifications.WatchedGameNotice;
import client.ui.common.watch.WatchController;
import client.ui.common.watch.widget.WatchWidget;
import easypubsub.Subscription;
import haxe.ui.core.Component;
import http.HttpError;
import net.models.challenge.ChallengeCreateResponse;
import net.models.challenge.mappers.ChallengeParamsMapper;
import net.models.challenge.mappers.IncomingChallengeMapper;
import net.models.challenge.mappers.OutgoingChallengeMapper;
import net.models.challenge.mappers.StartedGameMapper;
import net.models.common.RestErrorCode;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.UserRefMapper;
import net.models.game.OngoingGamePublic;
import net.models.game.mappers.OngoingGameMapper;
import net.rest.Rest;
import net.rest.RestErrors;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.Everyone;
import net.ws.channels.IncomingChallenges;
import net.ws.channels.OutgoingChallenges;
import net.ws.channels.PlayerOngoingGames;
import net.ws.events.IncomingChallengeAccepted;
import net.ws.events.IncomingChallengeCancelled;
import net.ws.events.IncomingChallengeDeclined;
import net.ws.events.IncomingChallengeReceived;
import net.ws.events.IncomingChallengesCancelledByServer;
import net.ws.events.IncomingChallengesRefresh;
import net.ws.events.OutgoingChallengeAccepted;
import net.ws.events.OutgoingChallengeCancelled;
import net.ws.events.OutgoingChallengeCreated;
import net.ws.events.OutgoingChallengeRejected;
import net.ws.events.OutgoingChallengesCancelledByServer;
import net.ws.events.OutgoingChallengesRefresh;
import net.ws.events.OngoingGameEnded;
import net.ws.events.OngoingGameStarted;
import net.ws.events.OngoingGameUpdated;
import net.ws.events.PlayerOngoingGamesRefresh;
import net.ws.events.ServerShutdown;

class Main
{
    /** Shorter than the server's away threshold, so that a resumed user never stays "away" until the next scheduled heartbeat **/
    private static inline final IDLE_THRESHOLD_SECS:Int = 60;

    private static var challengesWidget:ChallengesWidget;
    private static var challenges:ChallengesController;
    private static var incomingChallengesSubscription:Null<Subscription<IncomingChallenges>> = null;
    private static var outgoingChallengesSubscription:Null<Subscription<OutgoingChallenges>> = null;
    private static var challengesUserRef:Null<String> = null;
    private static var ongoingGamesWidget:OngoingGamesWidget;
    private static var accountWidget:AccountWidget;
    private static var ongoingGames:OngoingGamesController;
    private static var ongoingGamesSubscription:Null<Subscription<PlayerOngoingGames>> = null;
    private static var watchWidget:WatchWidget;
    private static var watch:WatchController;
    private static var watchedGamesSubscription:Null<Subscription<PlayerOngoingGames>> = null;
    private static var watchedStatusFeed:Null<PlayerStatusFeed> = null;

    public static function main():Void
    {
        LegacyUrlMigration.run();

        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setLeaveConfirmText("{{intellector.common.leave_confirm}}")
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
            .addRightMenubarItem(Widget(createWatchWidget, true))
            .addRightMenubarItem(Widget(createOngoingGamesWidget, true))
            .addRightMenubarItem(Widget(createChallengesWidget, true))
            .addRightMenubarItem(Widget(createAccountWidget, true))
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        // before the first page opens: it may load data right away
        var tokenRetriever:Void->Null<String> = () -> HaxeFolioApp.valueStorage.read(LocalStorageKey.TOKEN);
        Rest.init(tokenRetriever);
        ServerTime.init(Rest.serverClock().now);
        PubSub.start(tokenRetriever, () -> ActivityTracker.getLastActivityTs(), null, AuthBootstrap.run); // the token was rejected: revalidate it, falling back to the guest

        HaxeFolioApp.init(config);
        ConnectionNotice.init();
        PubSub.watchConnection(ConnectionNotice.onConnected, ConnectionNotice.onDisconnected);
        js.Browser.window.addEventListener("online", PubSub.reconnectNow);
        PubSub.listen(new Everyone()).onEventLight(ServerShutdown, _ -> InfoNotice.show("intellector.server_shutdown_notice.title", "intellector.server_shutdown_notice.text"));
        PreferenceMigration.run();
        ChallengeDraftMigration.run();
        CredentialsMigration.run();
        ActivityTracker.activate(IDLE_THRESHOLD_SECS, PubSub.sendHeartbeat);
        challenges = new ChallengesController(challengesWidget, acceptChallenge, declineChallenge, cancelChallenge, saveChallengeMarks);
        ChallengeMarksStorage.addExternalChangeHandler(() -> challengesUserRef, challenges.applyMarks);
        ongoingGames = new OngoingGamesController(ongoingGamesWidget);
        ongoingGamesWidget.currentGameId = () -> LiveGamePage.openGameId;
        GameRedirect.init(openStartedGame);
        watch = new WatchController(watchWidget);
        watchWidget.currentGameId = () -> LiveGamePage.openGameId;
        WatchedGameClaim.init(openWatchedGame, announceWatchedGame);
        ChallengeCreationLauncher.launch = presentChallengeCreation;
        IdentityKeeper.init([_ -> PubSub.reauth(), refreshAccountMenu, subscribeToChallenges, subscribeToOngoingGames]);
        WatchKeeper.init([subscribeToWatchedPlayer]);
        js.Browser.window.addEventListener("installpromptchange", refreshInstallItem);
        refreshInstallItem();
        AuthBootstrap.run();
    }

    private static function onCreateGamePressed():Void
    {
        presentChallengeCreation(null);
    }

    private static function onVersusBotPressed():Void
    {
        presentChallengeCreation(ChallengePrefills.versusBot);
    }

    private static function presentChallengeCreation(?prefill:ChallengeDraft->Void):Void
    {
        var identity:Identity = IdentityKeeper.currentIdentity;
        ChallengeCreationOverlay.present(identity.isGuest(), identity.getUserRef(), createChallenge, prefill);
    }

    private static function onWatchPlayerPressed():Void
    {
        PlayerSearchOverlay.present(LocaleUtils.localeBinding("intellector.overlay.player_search.title.watch_player"), true, watchFoundPlayer);
    }

    private static function watchFoundPlayer(player:FoundPlayer):Void
    {
        WatchKeeper.watch(new WatchedPlayer(player.login, player.nickname));
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

    private static function subscribeToChallenges(identity:Identity):Void
    {
        if (incomingChallengesSubscription != null)
        {
            incomingChallengesSubscription.detach();
            incomingChallengesSubscription = null;
        }

        if (outgoingChallengesSubscription != null)
        {
            outgoingChallengesSubscription.detach();
            outgoingChallengesSubscription = null;
        }

        challengesUserRef = null;
        challenges.reset();

        var userRef:Null<String> = identity.getUserRef();
        if (userRef == null)
            return;

        challengesUserRef = userRef;
        challenges.applyMarks(ChallengeMarksStorage.read(userRef));

        incomingChallengesSubscription = PubSub.sub(new IncomingChallenges(userRef))
            .onEventLight(IncomingChallengesRefresh, refresh -> challenges.syncIncoming(refresh.challenges.map(IncomingChallengeMapper.dtoToDatatype)))
            .onEventLight(IncomingChallengeReceived, challenge -> challenges.receiveIncoming(IncomingChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(IncomingChallengeCancelled, cancelled -> challenges.removeIncoming(cancelled.id))
            .onEventLight(IncomingChallengeAccepted, accepted -> challenges.removeIncoming(accepted.id))
            .onEventLight(IncomingChallengeDeclined, declined -> challenges.removeIncoming(declined.id))
            .onEventLight(IncomingChallengesCancelledByServer, cancelled -> {
                for (id in cancelled.ids)
                    challenges.removeIncoming(id);
            });

        outgoingChallengesSubscription = PubSub.sub(new OutgoingChallenges(userRef))
            .onEventLight(OutgoingChallengesRefresh, refresh -> onOutgoingChallengesRefresh(refresh.challenges.map(OutgoingChallengeMapper.dtoToDatatype)))
            .onEventLight(OutgoingChallengeCreated, challenge -> challenges.addOutgoing(OutgoingChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(OutgoingChallengeCancelled, cancelled -> challenges.removeOutgoing(cancelled.id))
            .onEventLight(OutgoingChallengeAccepted, accepted -> onOutgoingChallengeAccepted(accepted.id))
            .onEventLight(OutgoingChallengeRejected, rejected -> challenges.removeOutgoing(rejected.id))
            .onEventLight(OutgoingChallengesCancelledByServer, cancelled -> {
                for (id in cancelled.ids)
                    challenges.removeOutgoing(id);
            });
    }

    private static function subscribeToOngoingGames(identity:Identity):Void
    {
        if (ongoingGamesSubscription != null)
        {
            ongoingGamesSubscription.detach();
            ongoingGamesSubscription = null;
        }

        ongoingGames.reset();

        var userRef:Null<String> = identity.getUserRef();
        if (userRef == null)
            return;

        ongoingGamesSubscription = PubSub.sub(new PlayerOngoingGames(userRef))
            .onEventLight(PlayerOngoingGamesRefresh, refresh -> ongoingGames.sync([for (game in refresh.current_games) OngoingGameMapper.dtoToDatatype(game, userRef)]))
            .onEventLight(OngoingGameStarted, game -> ongoingGames.add(OngoingGameMapper.startedToDatatype(game, userRef)))
            .onEventLight(OngoingGameUpdated, update -> ongoingGames.update(update.game_id, game -> OngoingGameMapper.applyUpdate(game, update)))
            .onEventLight(OngoingGameEnded, ended -> ongoingGames.remove(ended.id));
    }

    private static function subscribeToWatchedPlayer(player:Null<WatchedPlayer>):Void
    {
        if (watchedGamesSubscription != null)
        {
            watchedGamesSubscription.detach();
            watchedGamesSubscription = null;
        }

        if (watchedStatusFeed != null)
        {
            watchedStatusFeed.detach();
            watchedStatusFeed = null;
        }

        watch.setPlayer(player);

        if (player == null)
            return;

        var login:String = player.login;
        watchedGamesSubscription = PubSub.sub(new PlayerOngoingGames(login))
            .onEventLight(PlayerOngoingGamesRefresh, refresh -> onWatchedGamesRefresh(refresh.current_games, login))
            .onEventLight(OngoingGameStarted, started -> {
                var game:OngoingGame = OngoingGameMapper.startedToDatatype(started, login);
                watch.add(game);
                if (!involvesUser(started.white_player.user_ref, started.black_player.user_ref))
                    onWatchedGameStarted(game);
            })
            .onEventLight(OngoingGameUpdated, update -> watch.update(update.game_id, game -> OngoingGameMapper.applyUpdate(game, update)))
            .onEventLight(OngoingGameEnded, ended -> {
                watch.remove(ended.id);
                WatchedGameClaim.cancel(ended.id);
                WatchedGameNotice.dismissFor(ended.id);
            });
        watchedStatusFeed = new PlayerStatusFeed([login], (_, status, _) -> watch.setStatus(status));
    }

    // a game listed anew after a reconnect may have started meanwhile
    private static function onWatchedGamesRefresh(dtos:Array<OngoingGamePublic>, login:String):Void
    {
        var games:Array<OngoingGame> = [for (dto in dtos) OngoingGameMapper.dtoToDatatype(dto, login)];
        var newIds:Array<Int> = watch.sync(games);

        for (i in 0...dtos.length)
            if (newIds.contains(dtos[i].id) && !involvesUser(dtos[i].white_player.user_ref, dtos[i].black_player.user_ref))
                onWatchedGameStarted(games[i]);
    }

    // the user's own games open through GameRedirect
    private static function involvesUser(whiteRef:String, blackRef:String):Bool
    {
        var userRef:Null<String> = IdentityKeeper.currentIdentity.getUserRef();
        return userRef != null && (whiteRef == userRef || blackRef == userRef);
    }

    private static function onWatchedGameStarted(game:OngoingGame):Void
    {
        if (game.id != LiveGamePage.openGameId)
            WatchedGameClaim.request(game);
    }

    private static function openWatchedGame(game:OngoingGame):Void
    {
        var reaction:WatchedGameReactionKind = WatchedGameReaction.decide(
            Preferences.watchedGameOpening.get(),
            HaxeFolioApp.currentPageMayBeLeft(),
            LiveGamePage.isShowingOwnOngoingTimedGame(),
            LiveGamePage.isShowingOthersOngoingTimedGame()
        );

        switch reaction
        {
            case Navigate:
                WatchedGameNotice.dismissFor(game.id);
                HaxeFolioApp.navigateTo(PagePaths.liveGame(game.id));
            case Announce:
                announceWatchedGame(game);
        }
    }

    private static function announceWatchedGame(game:OngoingGame):Void
    {
        var player:Null<WatchedPlayer> = WatchKeeper.watched;
        if (player != null)
            WatchedGameNotice.show(player.nickname, game);
    }

    private static function saveChallengeMarks(marks:ChallengeMarks):Void
    {
        if (challengesUserRef != null)
            ChallengeMarksStorage.save(challengesUserRef, marks);
    }

    // a challenge missing from a refresh may have been accepted while disconnected
    private static function onOutgoingChallengesRefresh(pending:Array<OutgoingChallenge>):Void
    {
        for (dropped in challenges.syncOutgoing(pending))
            redirectToResultingGame(dropped.id);
    }

    private static function onOutgoingChallengeAccepted(challengeId:Int):Void
    {
        challenges.removeOutgoing(challengeId);
        redirectToResultingGame(challengeId);
    }

    private static function redirectToResultingGame(challengeId:Int):Void
    {
        Rest.client().execute(
            RestOperationRegistry.GET_CHALLENGE,
            challenge -> {
                var game:Null<StartedGame> = StartedGameMapper.resultingGameToDatatype(challenge);
                if (game != null)
                    GameRedirect.request(game);
            },
            RequestFailureNotice.showHttpError.bind(OPEN_STARTED_GAME),
            ["challenge_id" => Std.string(challengeId)]
        );
    }

    private static function openStartedGame(game:StartedGame):Void
    {
        if (LiveGamePage.isShowingOwnOngoingGame())
            GameStartedNotice.show(game);
        else
            HaxeFolioApp.navigateTo('live/${game.id}');
    }


    private static function createChallenge(params:ChallengeParams, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        var calleeRef:Null<String> = params.target.calleeRef();
        var onCreated:ChallengeCreateResponse->Void = onChallengeCreated.bind(_, onOutcome);
        var onFailed:HttpError->Void = onCreateChallengeFailed.bind(_, calleeRef != null, onOutcome);

        switch params.target
        {
            case Player(_) | Guest(_):
                Rest.client().execute(RestOperationRegistry.CREATE_DIRECT_CHALLENGE, onCreated, onFailed, null, null, ChallengeParamsMapper.datatypeToDirectDto(params, calleeRef));
            case Public | LinkOnly:
                Rest.client().execute(RestOperationRegistry.CREATE_OPEN_CHALLENGE, onCreated, onFailed, null, null, ChallengeParamsMapper.datatypeToOpenDto(params, params.target == LinkOnly));
            case Bot:
                onOutcome(Failed); // no bot to play yet
        }
    }

    private static function onChallengeCreated(response:ChallengeCreateResponse, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        switch response.result
        {
            case MERGED:
                var ownUserRef:Null<String> = IdentityKeeper.currentIdentity.getUserRef();
                if (response.game != null && ownUserRef != null)
                    GameRedirect.request(StartedGameMapper.summaryToDatatype(response.game, ownUserRef));
                onOutcome(GameStarted);
            case CREATED:
                var callee:Null<UserRefWithNickname> = response.challenge?.callee;
                if (response.callee_online == false && callee != null)
                    CalleeOfflineNotice.show(UserRefMapper.displayName(callee), response.callee_session_lost == true);
                onOutcome(Created);
        }
    }

    private static function onCreateChallengeFailed(error:HttpError, direct:Bool, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        if (direct && RestErrors.codeOf(error) == RestErrorCode.CALLEE_NOT_FOUND)
        {
            onOutcome(CalleeNotFound);
            return;
        }

        RequestFailureNotice.showHttpError(CREATE_CHALLENGE, error);
        onOutcome(Failed);
    }

    private static function acceptChallenge(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.ACCEPT_CHALLENGE,
            game -> {
                challenges.acceptSucceeded();
                HaxeFolioApp.navigateTo('live/${game.id}');
            },
            onAcceptFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    private static function onAcceptFailed(challenge:IncomingChallenge, error:HttpError):Void
    {
        challenges.acceptFailed(challenge.id);

        if (isChallengeResolved(error))
        {
            challenges.removeIncoming(challenge.id);
            RequestFailureNotice.show(ACCEPT_CHALLENGE, ChallengeUnavailable);
        }
        else
            RequestFailureNotice.showHttpError(ACCEPT_CHALLENGE, error);
    }

    private static function declineChallenge(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.DECLINE_CHALLENGE,
            _ -> {},
            onDeclineFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // already off display: put back unless the challenge is gone anyway
    private static function onDeclineFailed(challenge:IncomingChallenge, error:HttpError):Void
    {
        if (isChallengeResolved(error))
            return;

        challenges.declineFailed(challenge);
        RequestFailureNotice.showHttpError(DECLINE_CHALLENGE, error);
    }

    private static function cancelChallenge(challenge:OutgoingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.CANCEL_CHALLENGE,
            _ -> {},
            onCancelFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // already off display: put back unless the challenge is gone anyway
    private static function onCancelFailed(challenge:OutgoingChallenge, error:HttpError):Void
    {
        if (isChallengeResolved(error))
            return;

        challenges.cancelFailed(challenge);
        RequestFailureNotice.showHttpError(CANCEL_CHALLENGE, error);
    }

    // not found, or no longer active: cancelled, accepted or declined already
    private static function isChallengeResolved(error:HttpError):Bool
    {
        return error.httpStatus == 404 || error.httpStatus == 422;
    }
}
