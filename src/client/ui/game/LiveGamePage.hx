package client.ui.game;

import client.ServerTime;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.game.GameChatMessage;
import client.datatypes.game.GameClock;
import client.datatypes.game.GameEnding;
import client.datatypes.game.GameParticipant;
import client.datatypes.game.LiveGameChange;
import client.datatypes.game.LiveGameEvent;
import client.datatypes.game.LiveGameInfo;
import client.datatypes.game.LiveGameState;
import client.datatypes.game.OfferAction;
import client.datatypes.game.OfferKind;
import client.datatypes.game.PlyHistory;
import client.datatypes.game.PlyHistory.ShownPly;
import client.datatypes.game.PlyNavigationType;
import client.datatypes.request.FailedAction;
import client.formatters.GameFormatters;
import client.logic.game.OpeningLookup;
import client.openings.OpeningEntry;
import client.ui.BoardLayoutTier;
import client.ui.common.board.InteractiveBoard;
import client.ui.common.board.MoveRulesAdapter;
import client.ui.common.board.Premoves;
import client.ui.common.board.tools.InertMovePolicy;
import client.ui.common.board.tools.LiveGameMovePolicy;
import client.ui.common.notifications.GameEndedNotice;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.game.GameLayout.CompactTab;
import easypubsub.Subscription;
import haxe.Timer;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import http.HttpError;
import intellectorboard.mappers.notation.PlyFormatter;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import net.models.game.GameAddTimePayload;
import net.models.game.GamePublic;
import net.models.game.GameSendChatMessagePayload;
import net.models.game.GameStateRefresh;
import net.models.game.mappers.GameClockMapper;
import net.models.game.internal.InternalGameResignPayload;
import net.models.game.mappers.LiveGameMapper;
import net.models.other.SubscriberListChannelStateRefresh;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.Game as GameChannel;
import net.ws.channels.SubscriberList;
import net.ws.events.GameEnded as GameEndedEvent;
import net.ws.events.GameRefresh as GameRefreshEvent;
import net.ws.events.NewChatMessage as NewChatMessageEvent;
import net.ws.events.NewPly as NewPlyEvent;
import net.ws.events.NewSubscriber as NewSubscriberEvent;
import net.ws.events.OfferActionPerformed as OfferActionPerformedEvent;
import net.ws.events.Rollback as RollbackEvent;
import net.ws.events.SubscriberLeft as SubscriberLeftEvent;
import net.ws.events.SubscriberListRefresh as SubscriberListRefreshEvent;
import net.ws.events.TimeAdded as TimeAddedEvent;

/**
    A game by id: one the user plays, one they watch, or a finished one. Loads the game, then follows
    it live over the game channel; a game that ends while open turns into a finished one in place.
**/
class LiveGamePage extends PageBase
{
    private static inline final LOAD_TIMEOUT_MS:Int = 10000;
    private static inline final CLOCK_REFRESH_MS:Int = 200;
    private static inline final LOW_TIME_MS:Float = 60 * 1000;
    // a game starting with less has no low time warning: it would sound almost at once
    private static inline final LOW_TIME_WARNING_MIN_START_SECONDS:Int = 90;
    // below it, the wide layout stops shrinking and the page scrolls instead
    private static inline final MIN_WIDE_HEIGHT:Float = 520;

    /** The id of the game the open live game page shows, null while none is open **/
    public static var openGameId(default, null):Null<Int> = null;

    private static var openPage:Null<LiveGamePage> = null;

    private final gameId:Int;

    private var statusBox:Null<VBox> = null;
    private var loadAttempt:Int = 0;
    private var loadTimer:Null<Timer> = null;

    private var gameSubscription:Null<Subscription<GameChannel>> = null;
    private var presenceSubscription:Null<Subscription<SubscriberList<Dynamic>>> = null;
    // live events arriving before the game has loaded, applied once it has
    private var pendingEvents:Array<Void->Void> = [];
    private var presentRefs:Array<String> = [];

    private var state:Null<LiveGameState> = null;
    private var userColor:Null<PieceColor> = null;
    private var orientation:PieceColor = White;
    private var resignAsked:Bool = false;
    private var timeoutCheckedFor:Null<GameClock> = null;
    private var lowTimeSounded:Bool = false;

    private var board:Null<InteractiveBoard> = null;
    private var premoves:Null<Premoves> = null;
    private var stage:Null<BoardStage> = null;
    private var gameLayout:Null<GameLayout> = null;
    private var infoCard:Null<GameInfoCard> = null;
    private var chatCard:Null<ChatCard> = null;
    private var movesCard:Null<MovesCard> = null;
    private var actionsCard:Null<ActionsCard> = null;
    private var moveStrip:Null<MoveStrip> = null;
    private var notations:Array<String> = [];

    private var clockTimer:Null<Timer> = null;
    private var handles:Array<Detachable> = [];

    public function new(gameId:Int)
    {
        super();
        this.gameId = gameId;
    }

    /** Whether a game the user plays, and which hasn't ended, is open **/
    public static function isShowingOwnOngoingGame():Bool
    {
        return openPage != null && openPage.userColor != null && openPage.state != null && !openPage.state.isOver();
    }

    private override function init():Void
    {
        openGameId = gameId;
        openPage = this;
        addClass(StyleClass.GAME_PAGE);
        setTitle(LocaleUtils.localeBinding("intellector.live_game.title"), gameId);

        subscribe();
        IdentityKeeper.addChangeListener(onIdentityChanged);
        load();
    }

    private override function onClose():Void
    {
        if (openGameId == gameId)
            openGameId = null;
        if (openPage == this)
            openPage = null;

        IdentityKeeper.removeChangeListener(onIdentityChanged);
        stopLoadTimer();
        if (clockTimer != null)
            clockTimer.stop();
        if (gameSubscription != null)
            gameSubscription.detach();
        if (presenceSubscription != null)
            presenceSubscription.detach();
        for (handle in handles)
            handle.detach();
        handles = [];
        if (board != null)
            board.dispose();
        if (stage != null)
            stage.dispose();
    }

    private function load():Void
    {
        loadAttempt++;
        var attempt:Int = loadAttempt;
        if (state == null)
            showStatus(LocaleUtils.localeBinding("intellector.live_game.status.loading"));

        stopLoadTimer();
        loadTimer = Timer.delay(() -> {
            if (attempt == loadAttempt)
                onLoadFailed("intellector.live_game.status.timeout");
        }, LOAD_TIMEOUT_MS);

        Rest.client().execute(
            RestOperationRegistry.GET_GAME,
            game -> {
                if (attempt == loadAttempt)
                    onLoaded(game);
            },
            error -> {
                if (attempt == loadAttempt)
                {
                    if (error.httpStatus == 404)
                        onGameNotFound();
                    else
                        onLoadFailed("intellector.live_game.status.failed");
                }
            },
            ["game_id" => Std.string(gameId)]
        );
    }

    private function stopLoadTimer():Void
    {
        if (loadTimer != null)
            loadTimer.stop();
        loadTimer = null;
    }

    private function onLoadFailed(textKey:String):Void
    {
        stopLoadTimer();
        loadAttempt++;
        if (state == null)
            showStatus(LocaleUtils.localeBinding(textKey), null, "intellector.live_game.status.retry", load);
    }

    // nothing to retry: the user goes looking for another game
    private function onGameNotFound():Void
    {
        stopLoadTimer();
        loadAttempt++;
        showStatus(LocaleUtils.localeBinding("intellector.live_game.status.not_found", Std.string(gameId)), "intellector.live_game.status.not_found_hint", "intellector.live_game.status.to_main_page", HaxeFolioApp.navigateToDefault);
    }

    /** `text`: a locale binding; `actionKey`/`onAction`: the button under it, if any **/
    private function showStatus(text:String, ?hintKey:String, ?actionKey:String, ?onAction:Void->Void):Void
    {
        if (statusBox != null)
            removeComponent(statusBox);

        statusBox = new VBox();
        statusBox.addClass(StyleClass.GAME_STATUS);
        statusBox.horizontalAlign = "center";
        statusBox.verticalAlign = "center";

        var label:Label = new Label();
        label.text = text;
        label.horizontalAlign = "center";
        label.addClass(StyleClass.GAME_STATUS_TEXT);
        statusBox.addComponent(label);

        if (hintKey != null)
        {
            var hintLabel:Label = new Label();
            hintLabel.text = LocaleUtils.localeBinding(hintKey);
            hintLabel.horizontalAlign = "center";
            hintLabel.addClass(StyleClass.GAME_STATUS_HINT);
            statusBox.addComponent(hintLabel);
        }

        if (actionKey != null && onAction != null)
        {
            var actionButton:Button = new Button();
            actionButton.text = LocaleUtils.localeBinding(actionKey);
            actionButton.horizontalAlign = "center";
            actionButton.addClass(StyleClass.GAME_BUTTON);
            actionButton.addClass(StyleClass.GAME_BUTTON_PRIMARY); // the screen's only action, on the bare page background
            actionButton.onClick = _ -> onAction();
            statusBox.addComponent(actionButton);
        }

        addComponent(statusBox);
    }

    private function onLoaded(game:GamePublic):Void
    {
        stopLoadTimer();
        loadAttempt++;

        var events:Array<LiveGameEvent> = LiveGameMapper.eventsToDatatype(game.events);
        var latestClock:Null<GameClock> = GameClockMapper.dtoToDatatype(game.latest_time_update);
        var ending:Null<GameEnding> = LiveGameMapper.outcomeToDatatype(game.outcome);

        if (state != null)
        {
            state.resync(events, latestClock, ending, followsLatestMove());
            refreshPlies();
            return;
        }

        if (statusBox != null)
        {
            removeComponent(statusBox);
            statusBox = null;
        }

        var info:LiveGameInfo = LiveGameMapper.infoToDatatype(game);
        state = new LiveGameState(info, events, latestClock, ending);
        userColor = info.colorOf(IdentityKeeper.currentIdentity.getUserRef());
        orientation = userColor ?? White;
        build(info);

        for (applyPending in pendingEvents)
            applyPending();
        pendingEvents = [];

        if (!state.isOver())
            Sounds.play(NOTIFY);
    }

    private function build(info:LiveGameInfo):Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        board = new InteractiveBoard(state.history.shownPosition(), orientation, new InertMovePolicy());
        board.setLastMove(shownPlyCount > 0 ? state.history.plyAt(shownPlyCount - 1) : null);
        handles.push(board.playMove.subscribe(onOwnMove));

        stage = new BoardStage(board, openProfile);
        stage.onFitted = fitLayoutHeight; // compact: the parts around the board can change height after it's fitted
        infoCard = new GameInfoCard(openProfile);
        chatCard = new ChatCard(sendChatMessage, message -> openProfileOfRef(message.authorRef));
        movesCard = new MovesCard(navigate);
        actionsCard = new ActionsCard({
            onFlip: flip,
            onDraw: () -> toggleOffer(Draw),
            onTakeback: () -> toggleOffer(Takeback),
            onResign: askResign,
            onAddTime: addTime,
            onAnalyze: () -> {},
            onShare: () -> {},
            onPlayFromHere: () -> {},
            onRematch: () -> {}
        });
        moveStrip = new MoveStrip(navigate, () -> gameLayout.setOpenTab(Moves));

        gameLayout = new GameLayout(infoCard, chatCard, movesCard, actionsCard, stage, moveStrip);
        refreshHeadTexts();
        addComponent(gameLayout);
        handles.push(BoardLayoutTier.bind(tier -> {
            gameLayout.setTier(tier);
            fitLayoutHeight();
        }));

        infoCard.setInfo(info);
        handles.push(state.history.onShownChanged.subscribe(onShownChanged));
        handles.push(state.onChanged.subscribe(onStateChanged));

        refreshPlayerBars();
        refreshMoves();
        refreshShown();
        refreshChat();
        refreshEnding();
        refreshRole();

        clockTimer = new Timer(CLOCK_REFRESH_MS);
        clockTimer.run = refreshClocks;
    }

    private override function onResize(width:Float, height:Float):Void
    {
        fitLayoutHeight();
    }

    /*
        Pages flow in a scrolling area, so the wide layout takes the area's height explicitly: the
        area's visible height less the insets above the layout, mirrored below it. The compact
        layout flows, its board shrinking for the rest to fit that height too.
    */
    private function fitLayoutHeight():Void
    {
        if (gameLayout == null)
            return;

        Toolkit.callLater(() -> {
            var scrollArea:Null<js.html.Element> = this.element.closest(".haxefolio-scroll-area");
            if (scrollArea == null || gameLayout == null)
                return;

            var inset:Float = gameLayout.element.getBoundingClientRect().top - scrollArea.getBoundingClientRect().top + scrollArea.scrollTop;
            var availableHeight:Float = Math.floor(scrollArea.clientHeight - 2 * inset);
            if (gameLayout.isCompact())
                stage.setMaxHeight(Math.floor(gameLayout.compactStageMaxHeight(availableHeight)));
            else
            {
                stage.setMaxHeight(null);
                gameLayout.height = Math.max(MIN_WIDE_HEIGHT, availableHeight);
            }
        });
    }

    private function subscribe():Void
    {
        var channel:GameChannel = new GameChannel(gameId);
        gameSubscription = PubSub.sub(channel)
            .onEventLight(GameRefreshEvent, refresh -> whenLoaded(() -> onRefresh(refresh)))
            .onEventLight(NewPlyEvent, ply -> whenLoaded(() -> applyEvent(LiveGameMapper.plyToDatatype(ply))))
            .onEventLight(NewChatMessageEvent, message -> whenLoaded(() -> applyEvent(LiveGameMapper.chatMessageToDatatype(message))))
            .onEventLight(OfferActionPerformedEvent, offer -> whenLoaded(() -> applyEvent(LiveGameMapper.offerToDatatype(offer))))
            .onEventLight(TimeAddedEvent, timeAdded -> whenLoaded(() -> applyEvent(LiveGameMapper.timeAddedToDatatype(timeAdded))))
            .onEventLight(RollbackEvent, rollback -> whenLoaded(() -> applyEvent(LiveGameMapper.rollbackToDatatype(rollback))))
            .onEventLight(GameEndedEvent, ended -> whenLoaded(() -> onEnded(LiveGameMapper.endedToDatatype(ended))));

        presenceSubscription = PubSub.sub(new SubscriberList<Dynamic>(channel))
            .onEventLight(SubscriberListRefreshEvent, onPresenceRefresh)
            .onEventLight(NewSubscriberEvent, subscriber -> {
                if (subscriber != null)
                    setPresent(subscriber.user_ref, true);
            })
            .onEventLight(SubscriberLeftEvent, subscriber -> {
                if (subscriber != null)
                    setPresent(subscriber.user_ref, false);
            });
    }

    private function whenLoaded(apply:Void->Void):Void
    {
        if (state != null)
            apply();
        else
            pendingEvents.push(apply);
    }

    private function onRefresh(refresh:GameStateRefresh):Void
    {
        var events:Array<LiveGameEvent> = LiveGameMapper.eventsToDatatype(refresh.events);
        state.resync(events, GameClockMapper.dtoToDatatype(refresh.latest_time_update), LiveGameMapper.outcomeToDatatype(refresh.outcome), followsLatestMove());
        refreshPlies();
    }

    private function applyEvent(event:LiveGameEvent):Void
    {
        var plyCountBefore:Int = state.history.plyCount();
        var applied:Bool = state.apply(event, followsLatestMove());
        if (event.match(Ply(_, _, _, _)) && state.history.plyCount() == plyCountBefore + 1)
            playLatestPlySound();

        if (!applied)
            load(); // missed events: catch up from the full game
        refreshPlies();
    }

    private function onEnded(ending:GameEnding):Void
    {
        if (state.isOver())
            return;

        var wasPlaying:Bool = isPlaying();
        state.end(ending);
        Sounds.play(NOTIFY);
        GameEndedNotice.show(state.info, ending, userColor);

        if (wasPlaying)
            load(); // brings in the spectators' messages, kept from players until now
    }

    private function onPresenceRefresh(refresh:SubscriberListChannelStateRefresh):Void
    {
        presentRefs = [for (subscriber in refresh.subscribers) subscriber.user_ref];
        refreshPresence();
    }

    private function setPresent(userRef:String, present:Bool):Void
    {
        presentRefs.remove(userRef);
        if (present)
            presentRefs.push(userRef);
        refreshPresence();
    }

    private function onShownChanged(shown:ShownPly):Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        board.setPosition(shown.position, shown.cause);
        if (state.history.shownPlyIndex() != shownPlyCount)
            return; // a premove fired by the new position has already shown the one after it

        board.setLastMove(shown.lastMove);
        refreshShown();
        refreshPolicy();
    }

    private function onStateChanged(change:LiveGameChange):Void
    {
        switch change
        {
            case Chat(appended):
                if (appended == null)
                    refreshChat();
                else if (isChatMessageVisible(appended))
                {
                    chatCard.appendMessage(appended);
                    gameLayout.setLatestMessage(appended, appended.authorRef != IdentityKeeper.currentIdentity.getUserRef());
                }
            case Offers:
                refreshOffers();
            case Clock:
                timeoutCheckedFor = null;
                refreshClocks();
            case Ended:
                refreshEnding();
                refreshRole();
        }
    }

    private function onIdentityChanged(_:Identity):Void
    {
        if (state == null)
            return;

        var newColor:Null<PieceColor> = state.info.colorOf(IdentityKeeper.currentIdentity.getUserRef());
        if (newColor == userColor)
            return;

        userColor = newColor;
        refreshRole();
        refreshChat();
    }

    private function refreshRole():Void
    {
        var playing:Bool = isPlaying();

        if (playing && premoves == null)
            premoves = board.enablePremoves(userColor, MoveRulesAdapter.DEFAULT);
        else if (!playing && premoves != null)
        {
            board.disablePremoves();
            premoves = null;
        }
        board.setUserMovesEnabled(playing);

        if (playing)
            actionsCard.showPlayerActions(state.info.isTimed());
        else
            actionsCard.showViewerActions(userColor != null);

        refreshPolicy();
        refreshOffers();
    }

    private function refreshPolicy():Void
    {
        var canMove:Bool = isPlaying() && state.history.isShowingLatest();
        board.setPolicy(canMove ? new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, userColor, premoves) : new InertMovePolicy());
    }

    private function refreshPlayerBars():Void
    {
        var top:PieceColor = orientation.opposite();
        stage.topBar.setParticipant(state.info.participant(top));
        stage.bottomBar.setParticipant(state.info.participant(orientation));
        refreshPresence();
        refreshClocks();
    }

    private function refreshPresence():Void
    {
        if (state == null)
            return;

        for (color in [White, Black])
        {
            var present:Bool = presentRefs.contains(state.info.participant(color).ref);
            infoCard.setPresent(color, present);
            (color == orientation ? stage.bottomBar : stage.topBar).setPresent(present);
        }
    }

    private function refreshClocks():Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        var clock:Null<GameClock> = state.clockAt(shownPlyCount);
        var nowMs:Float = ServerTime.now();

        for (color in [White, Black])
        {
            var bar:PlayerBar = color == orientation ? stage.bottomBar : stage.topBar;
            var remainingMs:Null<Float> = clock != null ? clock.remainingMs(color, nowMs) : null;
            bar.setClock(remainingMs, clock != null && clock.tickingSide == color);
        }

        var latestClock:Null<GameClock> = state.clockAt(state.history.plyCount());
        checkTimeout(latestClock, nowMs);
        checkLowTime(latestClock, nowMs);
    }

    // once a game, when the user's own running clock drops below a minute
    private function checkLowTime(clock:Null<GameClock>, nowMs:Float):Void
    {
        if (lowTimeSounded || !isPlaying() || clock == null || clock.tickingSide != userColor)
            return;

        var startSeconds:Int = switch state.info.timeControl {
            case Fischer(instance): instance.startSeconds;
            case None: 0;
        }
        if (startSeconds < LOW_TIME_WARNING_MIN_START_SECONDS || clock.remainingMs(userColor, nowMs) >= LOW_TIME_MS)
            return;

        lowTimeSounded = true;
        Sounds.play(LOW_TIME);
    }

    private function playLatestPlySound():Void
    {
        var plyCount:Int = state.history.plyCount();
        Sounds.playPly(state.history.plyAt(plyCount - 1), state.history.positionAt(plyCount - 1));
    }

    // a running clock at 0: the server learns of it from a check, unless a move comes first
    private function checkTimeout(clock:Null<GameClock>, nowMs:Float):Void
    {
        if (clock == null || clock.tickingSide == null || state.isOver() || clock == timeoutCheckedFor)
            return;
        if (clock.remainingMs(clock.tickingSide, nowMs) > 0)
            return;

        timeoutCheckedFor = clock;
        Rest.client().execute(RestOperationRegistry.CHECK_TIMEOUT, _ -> {}, _ -> {}, ["game_id" => Std.string(gameId)]);
    }

    private function refreshMoves():Void
    {
        var plyCount:Int = state.history.plyCount();
        if (notations.length > plyCount)
            notations = notations.slice(0, plyCount);
        for (i in notations.length...plyCount)
            notations.push(PlyFormatter.toNotation(state.history.plyAt(i), state.history.positionAt(i)));

        movesCard.setMoves(notations, state.info.startingPosition.turnColor);
    }

    // the ply count changed, which the shown position may not have: the move list and what offers allow follow it
    private function refreshPlies():Void
    {
        refreshMoves();
        refreshShown();
        refreshOffers();
    }

    private function refreshShown():Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        var plyCount:Int = state.history.plyCount();
        movesCard.setShown(shownPlyCount, plyCount);
        moveStrip.setShown(shownPlyCount, plyCount, shownPlyCount > 0 ? notations[shownPlyCount - 1] : null);
        refreshOpening(shownPlyCount);
        refreshClocks();
    }

    // the opening of the line up to the shown position
    private function refreshOpening(shownPlyCount:Int):Void
    {
        var custom:Bool = state.info.customStartingPosition;
        var opening:Null<OpeningEntry> = custom ? null : OpeningLookup.find([for (i in 0...shownPlyCount + 1) state.history.positionAt(i)]);
        infoCard.setOpening(opening);
        movesCard.setOpening(opening, custom);
    }

    private function refreshHeadTexts():Void
    {
        var info:LiveGameInfo = state.info;
        gameLayout.setHeadTexts(
            () -> GameFormatters.timeControl(info.timeControl),
            () -> GameFormatters.ratedAndStart(info.rated, info.startedAtMs),
            () -> GameFormatters.resolution(state.getEnding())
        );
    }

    private function refreshChat():Void
    {
        var messages:Array<GameChatMessage> = state.getChat().filter(isChatMessageVisible);
        chatCard.setMessages(messages);
        gameLayout.setLatestMessage(messages.length > 0 ? messages[messages.length - 1] : null, false);
    }

    // a player can't see spectators' messages until the game is over
    private function isChatMessageVisible(message:GameChatMessage):Bool
    {
        return !message.spectator || !isPlaying();
    }

    private function refreshEnding():Void
    {
        infoCard.setEnding(state.getEnding());
        refreshHeadTexts();
        if (state.isOver())
            resignAsked = false;
        refreshChat();
        refreshClocks();
    }

    private function refreshOffers():Void
    {
        stage.requests.removeAllComponents();

        if (!isPlaying())
            return;

        var opponentColor:PieceColor = userColor.opposite();
        var opponentNickname:String = state.info.participant(opponentColor).nickname;
        var plyCount:Int = state.history.plyCount();

        if (state.hasOffer(Draw, opponentColor))
            stage.requests.addComponent(createOfferBar("intellector.live_game.request.draw", opponentNickname, Draw));
        if (state.hasOffer(Takeback, opponentColor))
            stage.requests.addComponent(createOfferBar("intellector.live_game.request.takeback", opponentNickname, Takeback));
        if (resignAsked)
            stage.requests.addComponent(createResignBar(plyCount < 2));

        var takebackThreshold:Int = state.info.startingPosition.turnColor == userColor ? 1 : 2;
        actionsCard.setDrawState(state.hasOffer(Draw, userColor), !state.hasOffer(Draw, opponentColor) && plyCount >= 2);
        actionsCard.setTakebackState(state.hasOffer(Takeback, userColor), !state.hasOffer(Takeback, opponentColor) && plyCount >= takebackThreshold);
        actionsCard.setResignIsAbort(plyCount < 2);
    }

    private function createOfferBar(textKey:String, opponentNickname:String, kind:OfferKind):OfferBar
    {
        var bar:OfferBar = new OfferBar();
        bar.setText(LocaleUtils.resolveText(LocaleUtils.localeBinding(textKey), opponentNickname));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.decline"), false, () -> performOfferAction(Decline, kind));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.accept"), true, () -> performOfferAction(Accept, kind));
        return bar;
    }

    private function createResignBar(abort:Bool):OfferBar
    {
        var bar:OfferBar = new OfferBar();
        bar.setText(LocaleUtils.localeBinding(abort ? "intellector.live_game.request.abort_confirm" : "intellector.live_game.request.resign_confirm"));
        bar.addAnswer(LocaleUtils.localeBinding("intellector.live_game.request.cancel"), false, () -> {
            resignAsked = false;
            refreshOffers();
        });
        bar.addAnswer(LocaleUtils.localeBinding(abort ? "intellector.live_game.action.abort" : "intellector.live_game.action.resign"), true, resign);
        return bar;
    }

    private function navigate(type:PlyNavigationType):Void
    {
        state.history.navigate(type);
    }

    private function flip():Void
    {
        orientation = orientation.opposite();
        board.setOrientation(orientation);
        refreshPlayerBars();
    }

    private function onOwnMove(ply:RawPly):Void
    {
        state.playOwn(ply, ServerTime.now());
        playLatestPlySound();
        refreshPlies();
        Rest.client().execute(
            RestOperationRegistry.APPEND_PLY_TO_INTERNAL_GAME,
            _ -> {},
            error -> {
                RequestFailureNotice.showHttpError(MAKE_MOVE, error);
                load(); // the move didn't happen: back to the server's version
            },
            null,
            null,
            LiveGameMapper.plyToDto(gameId, ply)
        );
    }

    private function toggleOffer(kind:OfferKind):Void
    {
        performOfferAction(state.hasOffer(kind, userColor) ? Cancel : Create, kind);
    }

    private function performOfferAction(action:OfferAction, kind:OfferKind):Void
    {
        var failedAction:FailedAction = switch [action, kind] {
            case [Create, Draw]: OFFER_DRAW;
            case [Cancel, Draw]: CANCEL_DRAW;
            case [_, Draw]: ANSWER_DRAW;
            case [Create, Takeback]: OFFER_TAKEBACK;
            case [Cancel, Takeback]: CANCEL_TAKEBACK;
            case [_, Takeback]: ANSWER_TAKEBACK;
        }
        Rest.client().execute(
            RestOperationRegistry.PERFORM_OFFER_ACTION_IN_INTERNAL_GAME,
            _ -> {},
            RequestFailureNotice.showHttpError.bind(failedAction),
            null,
            null,
            LiveGameMapper.offerActionToDto(gameId, action, kind)
        );
    }

    private function askResign():Void
    {
        resignAsked = true;
        refreshOffers();
    }

    private function resign():Void
    {
        resignAsked = false;
        refreshOffers();
        Rest.client().execute(
            RestOperationRegistry.RESIGN_INTERNAL_GAME,
            _ -> {},
            RequestFailureNotice.showHttpError.bind(RESIGN),
            null,
            null,
            ({game_id: gameId} : InternalGameResignPayload)
        );
    }

    private function addTime():Void
    {
        Rest.client().execute(
            RestOperationRegistry.GAME_ADD_TIME,
            _ -> {},
            RequestFailureNotice.showHttpError.bind(ADD_TIME),
            null,
            null,
            ({game_id: gameId} : GameAddTimePayload)
        );
    }

    private function sendChatMessage(text:String):Void
    {
        Rest.client().execute(
            RestOperationRegistry.GAME_SEND_CHAT_MESSAGE,
            _ -> chatCard.clearDraft(),
            RequestFailureNotice.showHttpError.bind(SEND_CHAT_MESSAGE),
            null,
            null,
            ({game_id: gameId, text: text} : GameSendChatMessagePayload)
        );
    }

    private function openProfile(participant:GameParticipant):Void
    {
        openProfileOfRef(participant.ref);
    }

    private function openProfileOfRef(userRef:String):Void
    {
        if (!StringTools.startsWith(userRef, "_") && !StringTools.startsWith(userRef, "+"))
            HaxeFolioApp.navigateTo('player/$userRef');
    }

    private function isPlaying():Bool
    {
        return userColor != null && state != null && !state.isOver() && !state.info.external;
    }

    private function followsLatestMove():Bool
    {
        return PlyHistory.followsLatestMove(Preferences.followLatestMove.get(), isPlaying());
    }
}
