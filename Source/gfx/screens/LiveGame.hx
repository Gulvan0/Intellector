package gfx.screens;

import struct.ChallengeParams;
import haxe.ui.validation.InvalidationFlags;
import GlobalBroadcaster;
import haxe.ui.containers.Card;
import gfx.game.*;
import haxe.ui.core.Component;
import utils.MathUtils;
import haxe.ui.core.Screen as HaxeUIScreen;
import browser.Url;
import net.shared.Outcome;
import serialization.PortableIntellectorNotation;
import gfx.common.ShareDialog;
import openfl.events.Event;
import haxe.Timer;
import serialization.GameLogParser;
import dict.Utils;
import gfx.Dialogs;
import openfl.Assets;
import struct.IntPoint;
import net.shared.ServerEvent;
import js.Browser;
import dict.Dictionary;
import net.EventProcessingQueue.INetObserver;
import serialization.GameLogParser.GameLogParserOutput;
import struct.Variant;
import struct.Ply;
import gfx.utils.PlyScrollType;
import gfx.game.GameActionBar.ActionBtn;
import haxe.ui.containers.HBox;
import gfx.basic_components.BoardWrapper;
import struct.Situation;
import gameboard.behaviors.EnemyMoveBehavior;
import gameboard.behaviors.PlayerMoveBehavior;
import gameboard.behaviors.StubBehavior;
import gameboard.behaviors.IBehavior;
import gameboard.GameBoard;
import utils.TimeControl;
import net.shared.PieceColor;
import haxe.exceptions.NotImplementedException;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/live_layout.xml"))
class LiveGame extends Screen implements INetObserver implements IGameBoardObserver implements IGlobalEventObserver
{
    private var board:GameBoard;
    private var boardWrapper:BoardWrapper;
    
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var orientationColor:PieceColor = White;

    private var isPastGame:Bool;
    private var gameID:Int;
    private var whiteRef:String;
    private var blackRef:String;
    private var timeControl:TimeControl;
    private var datetime:Date;
    private var outcome:Null<Outcome> = null;
    private var rated:Bool;
    private var getSecsLeftAfterMove:Null<(side:PieceColor, plyNum:Int)->Null<Float>>;

    private var netObservers:Array<INetObserver>;
    private var gameboardObservers:Array<IGameBoardObserver>;

    public static var MIN_SIDEBARS_WIDTH:Float = 200;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    public function onEnter()
    {
        Networker.addObserver(this);
        GlobalBroadcaster.addObserver(this);
        SceneManager.addResizeHandler(performValidation);
        Assets.getSound("sounds/notify.mp3").play();
        performValidation();
        Timer.delay(boardContainer.validateNow, 25);
    }

    public function onClose()
    {
        Networker.emitEvent(LeaveGame(gameID));

        FollowManager.stopFollowing();

        cWhiteClock.deactivate();
        cBlackClock.deactivate();
        lWhiteClock.deactivate();
        lBlackClock.deactivate();

        SceneManager.removeResizeHandler(performValidation);
        Networker.removeObserver(this);
        GlobalBroadcaster.removeObserver(this);
    }

    private function performValidation() 
    {
        var availableWidth:Float = HaxeUIScreen.instance.actualWidth;
        var availableHeight:Float = HaxeUIScreen.instance.actualHeight * 0.95;

        var compact:Bool = availableWidth / availableHeight < 1.16;
        var compactBoardHeight:Float = availableWidth * boardWrapper.inverseAspectRatio();
        var largeBoardMaxWidth:Float = availableHeight / boardWrapper.inverseAspectRatio();
        var bothBarsVisible:Bool = availableWidth >= largeBoardMaxWidth + 2 * MIN_SIDEBARS_WIDTH;

        cBlackPlayerHBox.hidden = !compact;
        cWhitePlayerHBox.hidden = !compact;
        cActionBar.hidden = !compact;
        cCreepingLine.hidden = !compact;
        cSpacer1.hidden = !compact;
        cSpacer2.hidden = !compact;

        lLeftBox.hidden = compact || !bothBarsVisible;
        lRightBox.hidden = compact;
        
        if (compact)
        {
            boardContainer.percentHeight = null;
            boardContainer.height = compactBoardHeight + 20;
        }
        else
        {
            boardContainer.height = null;
            boardContainer.percentHeight = 100;
        }

        if (bothBarsVisible)
        {
            lLeftBox.width = Math.min(MAX_SIDEBARS_WIDTH, (availableWidth - largeBoardMaxWidth) / 2);
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, (availableWidth - largeBoardMaxWidth) / 2);
        }
        else
        {
            lLeftBox.width = 20;
            lRightBox.width = MathUtils.clamp(availableWidth - largeBoardMaxWidth, MIN_SIDEBARS_WIDTH, MAX_SIDEBARS_WIDTH);
        }
    }

    //================================================================================================================================================================

    public function handleNetEvent(event:ServerEvent)
    {
        for (obs in netObservers)
            obs.handleNetEvent(event);

        switch event 
        {
            case GameEnded(outcome, _, _, newPersonalElo):
                Assets.getSound("sounds/notify.mp3").play();
                this.outcome = outcome;

                var message:String;
                if (playerColor != null)
                    message = Utils.getPlayerGameOverDialogMessage(outcome, playerColor, newPersonalElo);
                else
                    message = Utils.getSpectatorGameOverDialogMessage(outcome, whiteRef, blackRef);
                
                Dialogs.infoRaw(message, Dictionary.getPhrase(GAME_ENDED_DIALOG_TITLE));
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        for (obs in gameboardObservers)
            obs.handleGameBoardEvent(event);

        switch event 
        {
            case ContinuationMove(ply, _, _):
                Networker.emitEvent(Move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto));
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        board.handleGlobalEvent(event);
        gameinfobox.handleGlobalEvent(event);

        if (event.match(PreferenceUpdated(Markup)))
            boardContainer.invalidateComponentLayout(true);
    }

    private function onPlyScrollRequested(type:PlyScrollType)
    {
        cCreepingLine.performScroll(type);
        lNavigator.performScroll(type);
        board.applyScrolling(type);
        if (getSecsLeftAfterMove != null)
        {
            cWhiteClock.setTimeManually(getSecsLeftAfterMove(White, lNavigator.shownMove));
            cBlackClock.setTimeManually(getSecsLeftAfterMove(Black, lNavigator.shownMove));
            lWhiteClock.setTimeManually(getSecsLeftAfterMove(White, lNavigator.shownMove));
            lBlackClock.setTimeManually(getSecsLeftAfterMove(Black, lNavigator.shownMove));
        }
    }

    public function handleActionBtnPress(btn:ActionBtn)
    {
        switch btn 
        {
            case Resign:
                Networker.emitEvent(Resign);
            case ChangeOrientation:
                setOrientation(opposite(orientationColor));
            case OfferDraw:
                Networker.emitEvent(OfferDraw);
            case CancelDraw:
                Networker.emitEvent(CancelDraw);
            case OfferTakeback:
                Networker.emitEvent(OfferTakeback);
            case CancelTakeback:
                Networker.emitEvent(CancelTakeback);
            case AddTime:
                Networker.emitEvent(AddTime);
            case Rematch:
                var opponentRef:String = playerColor == White? blackRef : whiteRef;
                if (opponentRef.charAt(0) != "_")
                {
                    var params:ChallengeParams = ChallengeParams.rematchParams(opponentRef, playerColor, timeControl, rated, board.startingSituation);
                    Dialogs.specifyChallengeParams(params, true);
                }
                else
                    Networker.emitEvent(SimpleRematch);
            case Share:
                var gameLink:String = Url.getGameLink(gameID);
                var playedMoves:Array<Ply> = board.plyHistory.getPlySequence();
                var pin:String = PortableIntellectorNotation.serialize(board.startingSituation, playedMoves, whiteRef, blackRef, timeControl, datetime, outcome);

                var shareDialog:ShareDialog = new ShareDialog();
                shareDialog.initInGame(board.shownSituation, board.orientationColor, gameLink, pin, board.startingSituation, playedMoves);
                shareDialog.showShareDialog(board);
            case PlayFromHere:
                var params:ChallengeParams = ChallengeParams.playFromPosParams(board.shownSituation);
                Dialogs.specifyChallengeParams(params, true);
            case Analyze:
                SceneManager.toScreen(Analysis(getSerializedVariant(), board.plyHistory.pointer, null, null));
            case AcceptDraw:
                Networker.emitEvent(AcceptDraw);
            case DeclineDraw:
                Networker.emitEvent(DeclineDraw);
            case AcceptTakeback:
                Networker.emitEvent(AcceptTakeback);
            case DeclineTakeback:
                Networker.emitEvent(DeclineTakeback);
            case PrevMove:
                onPlyScrollRequested(Prev);
            case NextMove:
                onPlyScrollRequested(Next);
        }
        chatbox.reactToOwnAction(btn);
    }

    private function getSerializedVariant():String
    {
        var variant:Variant = new Variant(board.startingSituation);

        var path:Array<Int> = [];
        for (ply in board.plyHistory.getPlySequence())
        {
            variant.addChildToNode(ply, path);
            path.push(0);
        }

        return variant.serialize();
	}

    //================================================================================================================================================================

    private function setOrientation(newOrientationColor:PieceColor)
    {
        if (orientationColor == newOrientationColor)
            return;

        board.setOrientation(newOrientationColor);

        orientationColor = newOrientationColor;

        //Compact bars

        centerBox.removeComponent(cWhitePlayerHBox, false);
        centerBox.removeComponent(cBlackPlayerHBox, false);

        var upperBox:HBox = orientationColor == White? cBlackPlayerHBox : cWhitePlayerHBox;
        var lowerBox:HBox = orientationColor == White? cWhitePlayerHBox : cBlackPlayerHBox;

        centerBox.addComponentAt(upperBox, 2);
        centerBox.addComponentAt(lowerBox, 4);

        //Large cards & clocks

        lRightBox.removeComponent(lWhiteClock, false);
        lRightBox.removeComponent(lBlackClock, false);
        lRightBox.removeComponent(lWhiteLoginCard, false);
        lRightBox.removeComponent(lBlackLoginCard, false);

        var upperClock:Clock = newOrientationColor == White? lBlackClock : lWhiteClock;
        var bottomClock:Clock = newOrientationColor == White? lWhiteClock : lBlackClock;
        var upperLogin:Card = newOrientationColor == White? lBlackLoginCard : lWhiteLoginCard;
        var bottomLogin:Card = newOrientationColor == White? lWhiteLoginCard : lBlackLoginCard;

        lRightBox.addComponentAt(upperLogin, 0);
        lRightBox.addComponentAt(upperClock, 0);

        lRightBox.addComponent(bottomLogin);
        lRightBox.addComponent(bottomClock);
    }

    public function new(gameID:Int, constructor:LiveGameConstructor) 
    {
        super();

        board = new GameBoard(Live(constructor));
        chatbox.init(constructor);
        gameinfobox.init(constructor);

        this.gameID = gameID;
        this.netObservers = [board, gameinfobox, chatbox, lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock];
        this.gameboardObservers = [lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock];

        customEnterHandler = onEnter;
        customCloseHandler = onClose;
        
        cWhiteClock.resize(30);
        cBlackClock.resize(30);

        switch constructor 
        {
            case New(whiteRef, blackRef, playerElos, timeControl, _, startDatetime):
                this.isPastGame = false;
                this.playerColor = LoginManager.isPlayer(blackRef)? Black : White;
                this.whiteRef = whiteRef;
                this.blackRef = blackRef;
                this.timeControl = timeControl;
                this.datetime = startDatetime;
                this.outcome = null;
                this.rated = playerElos != null;
                this.getSecsLeftAfterMove = null;

                setOrientation(playerColor);

            case Ongoing(parsedData, _, followedPlayerLogin):
                this.isPastGame = false;
                this.playerColor = parsedData.getPlayerColor();
                this.whiteRef = parsedData.whiteRef;
                this.blackRef = parsedData.blackRef;
                this.timeControl = parsedData.timeControl;
                this.datetime = parsedData.datetime;
                this.outcome = parsedData.outcome;
                this.rated = parsedData.isRated();
                this.getSecsLeftAfterMove = null;

                if (followedPlayerLogin != null)
                    setOrientation(parsedData.getParticipantColor(followedPlayerLogin));
                else if (playerColor != null)
                    setOrientation(playerColor);
                else
                    setOrientation(White);

            case Past(parsedData, watchedPlyerLogin):
                this.isPastGame = true;
                this.playerColor = null;
                this.whiteRef = parsedData.whiteRef;
                this.blackRef = parsedData.blackRef;
                this.timeControl = parsedData.timeControl;
                this.datetime = parsedData.datetime;
                this.outcome = parsedData.outcome;
                this.rated = parsedData.isRated();
                this.getSecsLeftAfterMove = parsedData.msPerMoveDataAvailable? parsedData.getSecsLeftAfterMove : null;

                setOrientation(watchedPlyerLogin != null? parsedData.getParticipantColor(watchedPlyerLogin) : White);
        }

        board.addObserver(this);

        boardWrapper = new BoardWrapper(board, boardContainer);

        boardContainer.percentHeight = 100;
        boardContainer.addComponent(boardWrapper);

        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;

        cWhiteLoginLabel.text = lWhiteLoginLabel.text = Utils.playerRef(whiteRef);
        cBlackLoginLabel.text = lBlackLoginLabel.text = Utils.playerRef(blackRef);

        cWhiteClock.init(constructor, White);
        cBlackClock.init(constructor, Black);
        lWhiteClock.init(constructor, White);
        lBlackClock.init(constructor, Black);

        lNavigator.init(onPlyScrollRequested, Live(constructor));
        lActionBar.init(constructor, false, handleActionBtnPress);
        cCreepingLine.init(onPlyScrollRequested, Live(constructor));
        cActionBar.init(constructor, true, handleActionBtnPress);
    }
}