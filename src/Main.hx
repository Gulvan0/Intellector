import client.ServerTime;
import client.auth.AuthBootstrap;
import client.ui.Assets;
import client.ui.BoardLayoutTier;
import client.formatters.IdentityFormatters;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.storage.LocalStorageKey;
import client.storage.PreferenceMigration;
import client.ui.common.overlays.challenge.ChallengeCreationOverlay;
import client.ui.common.overlays.login.LoginOverlay;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import haxefolio.browser.ActivityTracker;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;
import haxefolio.menu.MenuFacade;
import client.ui.home.HomePage;
import client.ui.analysis.AnalysisPage;
import client.ui.game.LiveGamePage;
import client.ui.profile.ProfileLayoutTier;
import client.ui.profile.ProfilePage;
import client.ui.challenge.ChallengeJoiningPage;
import client.ui.demo.DemoChallengeServer;
import client.ui.demo.DemoPage;
import client.storage.ChallengeMarksStorage;
import client.tabs.GameRedirect;
import client.datatypes.challenge.creation.ChallengeCreationOutcome;
import client.datatypes.challenge.ChallengeMarks;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.request.FailedAction;
import client.datatypes.challenge.IncomingChallenge;
import client.datatypes.challenge.OutgoingChallenge;
import client.datatypes.game.StartedGame;
import client.ui.StyleVars;
import client.ui.common.challenges.ChallengesController;
import client.ui.common.challenges.widget.ChallengesWidget;
import client.ui.common.games.OngoingGamesController;
import client.ui.common.games.widget.OngoingGamesWidget;
import client.ui.common.notifications.CalleeOfflineNotice;
import client.ui.common.notifications.GameStartedNotice;
import client.ui.common.notifications.RequestFailureNotice;
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
import net.models.game.mappers.OngoingGameMapper;
import net.rest.Rest;
import net.rest.RestErrors;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
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

class Main
{
    /** Shorter than the server's away threshold, so that a resumed user never stays "away" until the next scheduled heartbeat **/
    private static inline final IDLE_THRESHOLD_SECS:Int = 60;

    @:allow(client.ui.demo) private static var challengesWidget:ChallengesWidget;
    @:allow(client.ui.demo) private static var challenges:ChallengesController;
    private static var incomingChallengesSubscription:Null<Subscription<IncomingChallenges>> = null;
    private static var outgoingChallengesSubscription:Null<Subscription<OutgoingChallenges>> = null;
    private static var challengesUserRef:Null<String> = null;
    private static var ongoingGamesWidget:OngoingGamesWidget;
    private static var ongoingGames:OngoingGamesController;
    private static var ongoingGamesSubscription:Null<Subscription<PlayerOngoingGames>> = null;

    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setDebounceMs(100)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Compact, 0)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Medium, BoardLayoutTier.MEDIUM_MIN_WIDTH, BoardLayoutTier.fitsMedium)
            .addWidthTier(BoardLayoutTier.SCALE, BoardLayoutTier.Wide, BoardLayoutTier.WIDE_MIN_WIDTH, BoardLayoutTier.fitsWide)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Narrow, 0)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Medium, ProfileLayoutTier.MEDIUM_MIN_WIDTH)
            .addWidthTier(ProfileLayoutTier.SCALE, ProfileLayoutTier.Wide, ProfileLayoutTier.WIDE_MIN_WIDTH)
            .setAppearance({selectionEmphasis: Outlined, geometry: {fieldHeight: {expanded: 37, collapsed: 44}}, shadows: StyleVars.HAXEFOLIO_SHADOWS}) // outlined: brass shares the board's hue family
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .addPage("home", params -> new HomePage(), true)
            .addPage("analysis", params -> new AnalysisPage())
            .addPage("study/{id}", params -> new AnalysisPage(Std.parseInt(params.get("id"))))
            .addPage("live/{gameID}", params -> new LiveGamePage(Std.parseInt(params.get("gameID"))))
            .addPage("player/{login}", params -> new ProfilePage(params.get("login")))
            .addPage("join/{id}", params -> new ChallengeJoiningPage(Std.parseInt(params.get("id"))))
            .addPage("demo", params -> new DemoPage())
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
            .addNormalMenuItem("learn", "demo", NavigateTo(() -> "demo"))
            .addLeftMenubarItem(NormalMenu("social", []))
            .addNormalMenuItem("social", "player_profile", Execute(onPlayerProfilePressed), Assets.menuItemIcon("player_profile"))
            .addNormalMenuItem("social", "vk", Link("https://vk.com/intellectorgroup", true), Assets.menuItemIcon("vk"))
            .addNormalMenuItem("social", "discord", Link("https://discord.gg/f8chehcnV5", true), Assets.menuItemIcon("discord"))
            .addNormalMenuItem("social", "iteration", Link("https://t.me/iteracia_club", true), Assets.menuItemIcon("iteration"))
            .addRightMenubarItem(Widget(createOngoingGamesWidget, true))
            .addRightMenubarItem(Widget(createChallengesWidget, true))
            .addRightMenubarItem(NormalMenu("account", []))
            .addNormalMenuItem("account", "my_profile", NavigateTo(getMyProfilePath), Assets.menuItemIcon("my_profile"), null, true)
            .addNormalMenuItem("account", "preferences", Execute(HaxeFolioApp.showPreferences), Assets.menuItemIcon("settings"))
            .addNormalMenuItem("account", "log_in", Execute(LoginOverlay.present), Assets.menuItemIcon("log_in"))
            .addNormalMenuItem("account", "log_out", Execute(AuthBootstrap.logOut), Assets.menuItemIcon("log_out"), null, true)
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        // before the first page opens: it may load data right away
        var tokenRetriever:Void->Null<String> = () -> HaxeFolioApp.valueStorage.read(LocalStorageKey.TOKEN);
        Rest.init(tokenRetriever);
        ServerTime.init(Rest.serverClock().now);
        PubSub.start(tokenRetriever, () -> ActivityTracker.getLastActivityTs(), null, AuthBootstrap.run); // the token was rejected: revalidate it, falling back to the guest

        HaxeFolioApp.init(config);
        PreferenceMigration.run();
        ActivityTracker.activate(IDLE_THRESHOLD_SECS, PubSub.sendHeartbeat);
        challenges = new ChallengesController(challengesWidget, acceptChallenge, declineChallenge, cancelChallenge, saveChallengeMarks);
        ChallengeMarksStorage.addExternalChangeHandler(() -> challengesUserRef, challenges.applyMarks);
        ongoingGames = new OngoingGamesController(ongoingGamesWidget);
        ongoingGamesWidget.currentGameId = () -> LiveGamePage.openGameId;
        GameRedirect.init(openStartedGame);
        IdentityKeeper.init([_ -> PubSub.reauth(), refreshAccountMenu, subscribeToChallenges, subscribeToOngoingGames]);
        AuthBootstrap.run();
    }

    private static function onCreateGamePressed():Void
    {
        var identity:Identity = IdentityKeeper.currentIdentity;
        ChallengeCreationOverlay.present(identity.isGuest(), identity.getUserRef(), createChallenge);
    }

    private static function onVersusBotPressed():Void
    {
        var identity:Identity = IdentityKeeper.currentIdentity;
        ChallengeCreationOverlay.present(identity.isGuest(), identity.getUserRef(), createChallenge, BOT);
    }

    private static function onWatchPlayerPressed():Void {} // no watching yet

    private static function onPlayerProfilePressed():Void
    {
        PlayerSearchOverlay.present(LocaleUtils.localeBinding("intellector.overlay.player_search.title.find_player"), false, player -> HaxeFolioApp.navigateTo('player/${player.login}'));
    }

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

    private static function createOngoingGamesWidget():Component
    {
        ongoingGamesWidget = new OngoingGamesWidget();
        return ongoingGamesWidget.dropdown;
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

    private static function saveChallengeMarks(marks:ChallengeMarks):Void
    {
        if (DemoChallengeServer.used) // temporary: the demo page's fake ids would outrank the real ones for good
            return;

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
                    CalleeOfflineNotice.show(callee.nickname);
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
        if (DemoChallengeServer.owns(challenge.id)) // temporary: the demo page's fake challenges never reach the server
        {
            DemoChallengeServer.accept(challenge, onAcceptFailed.bind(challenge));
            return;
        }

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
        if (DemoChallengeServer.owns(challenge.id)) // temporary: the demo page's fake challenges never reach the server
        {
            DemoChallengeServer.decline(challenge, onDeclineFailed.bind(challenge));
            return;
        }

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
        if (DemoChallengeServer.owns(challenge.id)) // temporary: the demo page's fake challenges never reach the server
        {
            DemoChallengeServer.cancel(challenge, onCancelFailed.bind(challenge));
            return;
        }

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
