package client.ui.game;

import client.logic.challenge.creation.ChallengePrefills;
import client.ui.common.overlays.challenge.ChallengeCreationLauncher;
import client.ServerTime;
import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.game.GameClock;
import client.datatypes.game.GameEnding;
import client.datatypes.game.LiveGameChange;
import client.datatypes.game.LiveGameEvent;
import client.datatypes.game.LiveGameInfo;
import client.datatypes.game.LiveGameState;
import client.datatypes.game.PlyHistory.ShownPly;
import client.datatypes.game.PlyNavigationType;
import client.datatypes.watch.WatchedPlayer;
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
import client.ui.common.overlays.share.ShareOverlay;
import client.ui.game.controllers.BotTurnController;
import client.ui.game.controllers.GameChatController;
import client.ui.game.controllers.GameClockTicker;
import client.ui.game.controllers.GameFeed;
import client.ui.game.controllers.GameOffersController;
import client.ui.game.controllers.GamePresenceController;
import client.ui.game.controllers.LiveGameSession;
import client.utils.PagePaths;
import client.watch.WatchKeeper;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import haxefolio.PageLink;
import intellectorboard.mappers.notation.PlyFormatter;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import net.models.game.GameAddTimePayload;
import net.models.game.GamePublic;
import net.models.game.mappers.GameClockMapper;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

using client.ui.ComponentExtension;

/**
    A game by id: one the user plays, one they watch, or a finished one. Loads the game, then follows
    it live over the game channel; a game that ends while open turns into a finished one in place.
**/
class LiveGamePage extends PageBase
{
    // below it, the wide layout stops shrinking and the page scrolls instead
    private static inline final MIN_WIDE_HEIGHT:Float = 240;
    // below this viewport height, a landscape viewport lays the page out as a rail instead of the medium layout, whose cards and board come out too small
    private static inline final RAIL_FALLBACK_MAX_HEIGHT:Int = 600;

    /** The id of the game the open live game page shows, null while none is open **/
    public static var openGameId(default, null):Null<Int> = null;

    private static var openPage:Null<LiveGamePage> = null;

    private final gameId:Int;

    private var statusBox:Null<VBox> = null;
    private var feed:Null<GameFeed> = null;
    private var presence:Null<GamePresenceController> = null;

    private var session:Null<LiveGameSession> = null;
    private var state:Null<LiveGameState> = null;

    private var clockTicker:Null<GameClockTicker> = null;
    private var offers:Null<GameOffersController> = null;
    private var botTurn:Null<BotTurnController> = null;
    private var chat:Null<GameChatController> = null;

    private var board:Null<InteractiveBoard> = null;
    private var premoves:Null<Premoves> = null;
    private var stage:Null<BoardStage> = null;
    private var gameLayout:Null<GameLayout> = null;
    private var boardTier:Null<BoardLayoutTier> = null;
    private var infoCard:Null<GameInfoCard> = null;
    private var chatCard:Null<ChatCard> = null;
    private var movesCard:Null<MovesCard> = null;
    private var actionsCard:Null<ActionsCard> = null;
    private var moveStrip:Null<MoveStrip> = null;
    private var notations:Array<String> = [];

    private var handles:Array<Detachable> = [];

    public function new(gameId:Int)
    {
        super();
        this.gameId = gameId;
    }

    /** Whether a game the user plays, and which hasn't ended, is open **/
    public static function isShowingOwnOngoingGame():Bool
    {
        return openPage != null && openPage.session != null && openPage.session.userColor != null && !openPage.state.isOver();
    }

    /** Whether a timed game the user plays, and which hasn't ended, is open **/
    public static function isShowingOwnOngoingTimedGame():Bool
    {
        return isShowingOwnOngoingGame() && openPage.state.info.isTimed();
    }

    /** Whether a timed game the user doesn't play, and which hasn't ended, is open **/
    public static function isShowingOthersOngoingTimedGame():Bool
    {
        return openPage != null && openPage.session != null && openPage.session.userColor == null && !openPage.state.isOver() && openPage.state.info.isTimed();
    }

    private override function init():Void
    {
        openGameId = gameId;
        openPage = this;
        addClass(StyleClass.GAME_PAGE);
        setTitle(LocaleUtils.localeBinding("intellector.live_game.title"), gameId);

        feed = new GameFeed(gameId, {
            onFirstLoadStarted: () -> showStatus(LocaleUtils.localeBinding("intellector.live_game.status.loading")),
            onFirstLoaded: onFirstLoaded,
            onCaughtUp: onCaughtUp,
            onFirstLoadFailed: textKey -> showStatus(LocaleUtils.localeBinding(textKey), null, "intellector.live_game.status.retry", feed.load),
            onNotFound: onGameNotFound,
            onSnapshot: onSnapshot,
            onEvent: applyEvent,
            onEnded: onEnded
        });
        presence = new GamePresenceController(feed.channel);
        IdentityKeeper.addChangeListener(onIdentityChanged);
        WatchKeeper.addChangeListener(onWatchedChanged);
        feed.load();
    }

    private override function onClose():Void
    {
        if (openGameId == gameId)
            openGameId = null;
        if (openPage == this)
            openPage = null;

        IdentityKeeper.removeChangeListener(onIdentityChanged);
        WatchKeeper.removeChangeListener(onWatchedChanged);
        if (feed != null)
            feed.dispose();
        if (presence != null)
            presence.dispose();
        if (clockTicker != null)
            clockTicker.stop();
        if (botTurn != null)
            botTurn.dispose();
        for (handle in handles)
            handle.detach();
        handles = [];
        if (board != null)
            board.dispose();
        if (stage != null)
            stage.dispose();
    }

    // nothing to retry: the user goes looking for another game
    private function onGameNotFound():Void
    {
        showStatus(LocaleUtils.localeBinding("intellector.live_game.status.not_found", Std.string(gameId)), "intellector.live_game.status.not_found_hint", "intellector.live_game.status.to_main_page", null, HaxeFolioApp.defaultPagePath);
    }

    /** `text`: a locale binding; `actionKey`: the button under it, if any, running `onAction` or - if there is none - linking to `actionPath` **/
    private function showStatus(text:String, ?hintKey:String, ?actionKey:String, ?onAction:Void->Void, ?actionPath:String):Void
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

        if (actionKey != null)
        {
            var actionButton:Button = new Button();
            actionButton.text = LocaleUtils.localeBinding(actionKey);
            actionButton.horizontalAlign = "center";
            actionButton.addClass(StyleClass.GAME_BUTTON);
            actionButton.addClass(StyleClass.GAME_BUTTON_PRIMARY); // the screen's only action, on the bare page background
            if (onAction != null)
                actionButton.onClick = _ -> onAction();
            else
                PageLink.attach(actionButton, actionPath);
            statusBox.addComponent(actionButton);
        }

        addComponent(statusBox);
    }

    private function onFirstLoaded(game:GamePublic):Void
    {
        if (statusBox != null)
        {
            removeComponent(statusBox);
            statusBox = null;
        }

        var info:LiveGameInfo = LiveGameMapper.infoToDatatype(game);
        state = new LiveGameState(info, LiveGameMapper.eventsToDatatype(game.events), GameClockMapper.dtoToDatatype(game.latest_time_update), LiveGameMapper.outcomeToDatatype(game.outcome));
        restoreShownPly();
        session = new LiveGameSession(gameId, state, info.colorOf(IdentityKeeper.currentIdentity.getUserRef()));
        build(info);
    }

    private function onCaughtUp():Void
    {
        botTurn.refreshTurn();

        if (!state.isOver())
            Sounds.play(NOTIFY);
    }

    private function onSnapshot(events:Array<LiveGameEvent>, latestClock:Null<GameClock>, ending:Null<GameEnding>):Void
    {
        state.resync(events, latestClock, ending, session.followsLatestMove());
        refreshPlies();
    }

    private function build(info:LiveGameInfo):Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        board = new InteractiveBoard(state.history.shownPosition(), session.orientation, new InertMovePolicy());
        board.setLastMove(shownPlyCount > 0 ? state.history.plyAt(shownPlyCount - 1) : null);
        handles.push(board.playMove.subscribe(onOwnMove));

        stage = new BoardStage(board);
        stage.onFitted = fitLayoutHeight; // compact: the parts around the board can change height after it's fitted
        infoCard = new GameInfoCard();
        infoCard.setWatchedLogin(watchedLogin());
        chatCard = new ChatCard(text -> chat.send(text));
        chatCard.setWatchedLogin(watchedLogin());
        movesCard = new MovesCard(navigate);
        actionsCard = new ActionsCard({
            onFlip: flip,
            onDraw: () -> offers.toggle(Draw),
            onTakeback: takeback,
            onResign: () -> offers.askResign(),
            onAddTime: addTime,
            onShare: share,
            onPlayFromHere: playFromHere,
            onRematch: rematch
        });
        moveStrip = new MoveStrip(navigate, () -> gameLayout.toggleTab(Moves));

        gameLayout = new GameLayout(infoCard, chatCard, movesCard, actionsCard, stage, moveStrip);
        clockTicker = new GameClockTicker(session, stage);
        offers = new GameOffersController(session, stage, actionsCard);
        botTurn = new BotTurnController(session, stage);
        chat = new GameChatController(session, chatCard, gameLayout);
        presence.attach(session, stage, infoCard, chatCard);
        refreshHeadTexts();
        addComponent(gameLayout);
        handles.push(BoardLayoutTier.bind(tier -> {
            boardTier = tier;
            applyTier();
        }));

        infoCard.setInfo(info);
        handles.push(state.history.onShownChanged.subscribe(onShownChanged));
        handles.push(state.onChanged.subscribe(onStateChanged));

        refreshPlayerBars();
        refreshMoves();
        refreshShown();
        chat.refresh();
        refreshEnding();
        refreshRole();
        refreshLastMove();

        clockTicker.start();
    }

    private override function onResize(width:Float, height:Float):Void
    {
        applyTier();
    }

    // the medium tier is swapped for the rail on a short viewport, which the tier scale, shared with the analysis page, doesn't do
    private function applyTier():Void
    {
        if (gameLayout == null || boardTier == null)
            return;

        var railForced:Bool = boardTier == Medium && js.Browser.window.innerHeight < RAIL_FALLBACK_MAX_HEIGHT && js.Browser.window.innerWidth > js.Browser.window.innerHeight;
        this.setClass(StyleClass.GAME_PAGE_FORCED_RAIL, railForced);
        gameLayout.setClass(StyleClass.GAME_FORCED_RAIL, railForced);
        gameLayout.setTier(railForced ? Rail : boardTier);
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
            gameLayout.fitHeadDetails();
        });
    }

    private function applyEvent(event:LiveGameEvent):Void
    {
        var plyCountBefore:Int = state.history.plyCount();
        var applied:Bool = state.apply(event, session.followsLatestMove());
        if (event.match(Ply(_, _, _, _)) && state.history.plyCount() == plyCountBefore + 1)
            playLatestPlySound();

        if (!applied)
            feed.load(); // diverged from the server: catch up from the full game
        refreshPlies();
    }

    private function onEnded(ending:GameEnding):Void
    {
        if (state.isOver())
            return;

        var wasPlaying:Bool = session.isPlaying();
        state.end(ending);
        botTurn.refreshTurn();
        presence.refresh();
        Sounds.play(NOTIFY);
        GameEndedNotice.show(state.info, ending, session.userColor);

        if (wasPlaying)
            feed.load(); // brings in the spectators' messages, kept from players until now
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
                chat.onChanged(appended);
            case Offers:
                offers.refresh();
            case Clock:
                clockTicker.onClockChanged();
                refreshLastMove();
            case Ended:
                refreshEnding();
                refreshRole();
        }
    }

    private function onWatchedChanged(_:Null<WatchedPlayer>):Void
    {
        if (stage == null)
            return;

        stage.topBar.setWatchedLogin(watchedLogin());
        stage.bottomBar.setWatchedLogin(watchedLogin());
        infoCard.setWatchedLogin(watchedLogin());
        chatCard.setWatchedLogin(watchedLogin());
    }

    private static function watchedLogin():Null<String>
    {
        return WatchKeeper.watched?.login;
    }

    private function onIdentityChanged(_:Identity):Void
    {
        if (session == null)
            return;

        var newColor:Null<PieceColor> = state.info.colorOf(IdentityKeeper.currentIdentity.getUserRef());
        if (newColor == session.userColor)
            return;

        session.userColor = newColor;
        refreshRole();
        chat.refresh();
        botTurn.refreshTurn();
    }

    private function refreshRole():Void
    {
        var playing:Bool = session.isPlaying();

        if (playing && premoves == null)
            premoves = board.enablePremoves(session.userColor, MoveRulesAdapter.DEFAULT);
        else if (!playing && premoves != null)
        {
            board.disablePremoves();
            premoves = null;
        }
        board.setUserMovesEnabled(playing);

        if (playing)
            actionsCard.showPlayerActions(state.info.isTimed(), state.info.bot != null);
        else
            actionsCard.showViewerActions(session.userColor != null);

        refreshPolicy();
        offers.refresh();
    }

    private function playFromHere():Void
    {
        var position:Position = state.history.shownPosition();
        ChallengeCreationLauncher.launch(draft -> ChallengePrefills.playFrom(draft, position));
    }

    private function rematch():Void
    {
        var info:LiveGameInfo = state.info;
        var color:Null<PieceColor> = session.userColor;
        if (color != null)
            ChallengeCreationLauncher.launch(draft -> ChallengePrefills.rematch(draft, info, color));
    }

    private function refreshPolicy():Void
    {
        var canMove:Bool = session.isPlaying() && state.history.isShowingLatest();
        board.setPolicy(canMove ? new LiveGameMovePolicy(MoveRulesAdapter.DEFAULT, session.userColor, premoves) : new InertMovePolicy());
    }

    private function refreshPlayerBars():Void
    {
        var top:PieceColor = session.orientation.opposite();
        stage.topBar.setParticipant(state.info.participant(top), watchedLogin());
        stage.bottomBar.setParticipant(state.info.participant(session.orientation), watchedLogin());
        presence.refresh();
        clockTicker.refresh();
        botTurn.refreshProgress();
    }

    private function playLatestPlySound():Void
    {
        var plyCount:Int = state.history.plyCount();
        Sounds.playPly(state.history.plyAt(plyCount - 1), state.history.positionAt(plyCount - 1));
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
        offers.refresh();
        botTurn.refreshTurn();
        refreshLastMove();
    }

    private function refreshShown():Void
    {
        var shownPlyCount:Int = state.history.shownPlyIndex();
        var plyCount:Int = state.history.plyCount();
        movesCard.setShown(shownPlyCount, plyCount);
        moveStrip.setShown(shownPlyCount, plyCount, shownPlyCount > 0 ? notations[shownPlyCount - 1] : null);
        actionsCard.setAnalysisPath(PagePaths.gameAnalysis(state.info.id, shownPlyCount));
        refreshOpening(shownPlyCount);
        clockTicker.refresh();
        HaxeFolioApp.setState(state.history.isShowingLatest() ? null : {shownPlyCount: shownPlyCount});
    }

    private function restoreShownPly():Void
    {
        var raw:Dynamic = HaxeFolioApp.navigationState;
        var restoredPlyCount:Dynamic = raw != null && Reflect.isObject(raw) ? Reflect.field(raw, "shownPlyCount") : null;

        if (Std.isOfType(restoredPlyCount, Int) && restoredPlyCount > 0)
        {
            var targetPlyCount:Int = restoredPlyCount;
            state.history.navigate(AfterPly(targetPlyCount - 1));
        }
    }

    // the opening of the line up to the shown position
    private function refreshOpening(shownPlyCount:Int):Void
    {
        var custom:Bool = state.info.customStartingPosition;
        var opening:Null<OpeningEntry> = custom ? null : OpeningLookup.find([for (i in 0...shownPlyCount + 1) state.history.positionAt(i)]);
        infoCard.setOpening(opening);
        movesCard.setOpening(opening, custom);
    }

    // a correspondence game tells when its latest move was made
    private function refreshLastMove():Void
    {
        var lastPlyAtMs:Null<Float> = state.lastPlyAtMs();
        var lastMoveText:Null<Void->String> = !state.info.isTimed() && lastPlyAtMs != null ? () -> GameFormatters.lastMove(lastPlyAtMs) : null;
        infoCard.setLastMove(lastMoveText);
        gameLayout.setHeadLastMove(lastMoveText);
        fitLayoutHeight(); // the head's second line changes its height
    }

    private function refreshHeadTexts():Void
    {
        var info:LiveGameInfo = state.info;
        gameLayout.setHeadTexts(
            () -> GameFormatters.timeControl(info.timeControl),
            () -> GameFormatters.ratedAndStart(info.rated, info.startedAtMs),
            () -> GameFormatters.resolution(state.getEnding())
        );
        fitLayoutHeight(); // the texts' widths decide whether the head's details fit
    }

    private function refreshEnding():Void
    {
        infoCard.setEnding(state.getEnding());
        refreshHeadTexts();
        if (state.isOver())
            offers.onEnded();
        chat.refresh();
        clockTicker.refresh();
    }

    private function navigate(type:PlyNavigationType):Void
    {
        state.history.navigate(type);
    }

    private function flip():Void
    {
        session.orientation = session.orientation.opposite();
        board.setOrientation(session.orientation);
        refreshPlayerBars();
    }

    private function share():Void
    {
        var plyCount:Int = state.history.plyCount();
        var shownPlyCount:Int = state.history.shownPlyIndex();

        ShareOverlay.present({
            position: state.history.shownPosition(),
            orientation: session.orientation,
            lastMove: shownPlyCount > 0 ? state.history.plyAt(shownPlyCount - 1) : null,
            game: {
                info: state.info,
                plies: [for (i in 0...plyCount) state.history.plyAt(i)],
                positions: [for (i in 0...plyCount + 1) state.history.positionAt(i)],
                ending: state.getEnding()
            }
        });
    }

    private function onOwnMove(ply:RawPly):Void
    {
        var position:Position = state.history.latestPosition();
        state.playOwn(ply, ServerTime.now());
        playLatestPlySound();
        refreshPlies();
        session.commands().move(ply, position, error -> {
            if (!state.info.isExternal() || error.httpStatus != 422) // an external game moved on elsewhere: nothing to tell
                RequestFailureNotice.showHttpError(MAKE_MOVE, error);
            feed.load(); // the move didn't happen: back to the server's version
        });
    }

    private function takeback():Void
    {
        if (state.info.bot == null)
            offers.toggle(Takeback);
        else
            botTurn.takeBack();
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
}
