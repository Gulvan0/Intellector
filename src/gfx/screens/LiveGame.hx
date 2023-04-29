package gfx.screens;

import haxe.ds.Option;
import net.shared.dataobj.TimeReservesData;
import engine.BotFactory;
import engine.BotTimeData;
import dict.Phrase;
import engine.Bot;
import net.shared.utils.PlayerRef;
import gameboard.util.BoardSize;
import GlobalBroadcaster;
import browser.Url;
import dict.Dictionary;
import dict.Utils;
import gameboard.GameBoard;
import gfx.Dialogs;
import gfx.common.ShareDialog;
import gfx.game.*;
import gfx.game.GameActionBar.ActionBtn;
import gfx.popups.ChallengeParamsDialog;
import gfx.utils.PlyScrollType;
import haxe.Timer;
import haxe.ui.containers.Card;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Screen as HaxeUIScreen;
import net.INetObserver;
import net.shared.Outcome;
import net.shared.PieceColor;
import net.shared.ServerEvent;
import net.shared.board.RawPly;
import net.shared.utils.MathUtils;
import assets.Audio;
import serialization.PortableIntellectorNotation;
import struct.ChallengeParams;
import struct.Variant;
import utils.TimeControl;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/live_layout.xml"))
class LiveGame extends Screen implements INetObserver implements IGameBoardObserver implements IGlobalEventObserver
{
    private var board:GameBoard;
    
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var orientationColor:PieceColor = White;

    private var isPastGame:Bool;
    private var botOpponent:Null<Bot> = null;
    private var gameID:Int;
    private var whiteRef:PlayerRef;
    private var blackRef:PlayerRef;
    private var timeControl:TimeControl;
    private var datetime:Date;
    private var outcome:Null<Outcome> = null;
    private var rated:Bool;
    private var getSecsLeftAfterMove:Null<(side:PieceColor, plyNum:Int)->Null<Float>>;

    private var netObservers:Array<INetObserver>;
    private var gameboardObservers:Array<IGameBoardObserver>;

    public static var MIN_SIDEBARS_WIDTH:Float = 250;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    public function onEnter()
    {
        Networker.addObserver(this);
        GlobalBroadcaster.addObserver(this);
        SceneManager.addResizeHandler(performValidation);
        Audio.playSound("notify");
        performValidation();
        Timer.delay(boardContainer.validateNow, 25);
    }

    public function onClose()
    {
        if (botOpponent != null)
            botOpponent.interrupt();

        if (FollowManager.followedGameID == gameID)
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

        var compact:Bool = availableWidth / availableHeight < 1.3;
        var compactBoardHeight:Float = availableWidth * BoardSize.inverseAspectRatio(board.lettersEnabled);
        var largeBoardMaxWidth:Float = availableHeight / BoardSize.inverseAspectRatio(board.lettersEnabled);
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
            boardContainer.height = Math.min(compactBoardHeight + 10, availableHeight - cCreepingLine.height - cActionBar.height - cBlackPlayerHBox.height - cWhitePlayerHBox.height - 45);
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

    private function onRematchRequested()
    {
        var opponentRef:PlayerRef = playerColor == White? blackRef : whiteRef;

        switch opponentRef.concretize() 
        {
            case Normal(login):
                var params:ChallengeParams = ChallengeParams.rematchParams(login, playerColor, timeControl, rated, board.startingSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Bot(handle):
                var params:ChallengeParams = ChallengeParams.botRematchParams(handle, playerColor, timeControl, rated, board.startingSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Guest(_):
                Networker.emitEvent(SimpleRematch);
        }
    }
    
    private function onContinuationMovePlayed(ply:RawPly)
    {
        if (botOpponent != null)
        {
            var reaction:Null<Phrase> = botOpponent.getReactionToMove(ply, board.currentSituation);
            if (reaction != null)
                botchat.appendBotMessage(botOpponent.name, Dictionary.getPhrase(reaction));
        }
        
        Networker.emitEvent(Move(ply));
    }

    private function makeBotMove(timeData:TimeReservesData)
    {
        var botTimeData:Null<BotTimeData> = null;
        if (!timeControl.isCorrespondence())
        {
            var moveNum:Int = board.plyHistory.length() + 1;
            var secsLeft:Float = timeData.getSecsLeftNow(board.currentSituation.turnColor, Date.now().getTime(), moveNum >= 3);
            botTimeData = new BotTimeData(secsLeft, timeControl.bonusSecs, moveNum, playerColor == Black);
        }

        var onBotMessage:Phrase->Void = phrase -> {
            botchat.appendBotMessage(botOpponent.name, Dictionary.getPhrase(phrase));
        };
        var onMoveChosen:RawPly->Void = ply -> {
            Networker.emitEvent(Move(ply));
            handleNetEvent(Move(ply, null));
        };
        
        botOpponent.playMove(board.currentSituation, botTimeData, onBotMessage, onMoveChosen);
    }

    //=================================================================================================================================================================

    public function handleNetEvent(event:ServerEvent)
    {
        for (obs in netObservers)
            obs.handleNetEvent(event);

        switch event 
        {
            case BotMove(timeData):
                makeBotMove(timeData);
            case GameEnded(outcome, _, _, newPersonalElo):
                Audio.playSound("notify");
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
                onContinuationMovePlayed(ply);
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        board.handleGlobalEvent(event);
        gameinfobox.handleGlobalEvent(event);

        switch event 
        {
            case LoggedIn:
                cActionBar.playFromPosBtn.disabled = false;
                lActionBar.playFromPosBtn.disabled = false;
            case LoggedOut:
                cActionBar.playFromPosBtn.disabled = true;
                lActionBar.playFromPosBtn.disabled = true;
            case PreferenceUpdated(Marking):
                boardContainer.invalidateComponentLayout(true);
            default:
        }
        
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
                if (botOpponent != null)
                    botOpponent.interrupt();
                Networker.emitEvent(Resign);
            case ChangeOrientation:
                setOrientation(opposite(orientationColor));
            case OfferDraw:
                Networker.emitEvent(OfferDraw);
            case CancelDraw:
                Networker.emitEvent(CancelDraw);
            case OfferTakeback:
                if (botOpponent != null)
                    botOpponent.interrupt();
                Networker.emitEvent(OfferTakeback);
            case CancelTakeback:
                Networker.emitEvent(CancelTakeback);
            case AddTime:
                Networker.emitEvent(AddTime);
            case Rematch:
                onRematchRequested();
            case Share:
                var gameLink:String = Url.getGameLink(gameID);
                var playedMoves:Array<RawPly> = board.plyHistory.getPlySequence();
                var pin:String = PortableIntellectorNotation.serialize(board.startingSituation, playedMoves, whiteRef, blackRef, timeControl, datetime, outcome);

                var shareDialog:ShareDialog = new ShareDialog();
                shareDialog.initInGame(board.shownSituation, board.orientationColor, gameLink, pin, board.startingSituation, playedMoves);
                shareDialog.showShareDialog(board);
            case PlayFromHere:
                var params:ChallengeParams = ChallengeParams.playFromPosParams(board.shownSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Analyze:
                SceneManager.toScreen(Analysis(getSerializedVariant(), board.plyHistory.pointer, null));
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
        this.netObservers = [gameinfobox, chatbox, lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock, board]; //Board should ALWAYS be the last observer in order for premoves to work correctly. Maybe someday I'll fix that, but atm it's troublesome
        this.gameboardObservers = [lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock];

        customEnterHandler = onEnter;
        customCloseHandler = onClose;
        
        cWhiteClock.resize(30);
        cBlackClock.resize(30);

        var ongoingTimeData:Option<TimeReservesData> = None;

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

            case Ongoing(parsedData, timeData, followedPlayerLogin):
                ongoingTimeData = Some(timeData);

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

        board.horizontalAlign = 'center';
        board.verticalAlign = 'center';
        board.percentHeight = 100;
        board.percentWidth = 100;

        boardContainer.percentHeight = 100;
        boardContainer.addComponent(board);

        var opponentRef:PlayerRef = playerColor == White? blackRef : whiteRef;
        switch opponentRef.concretize() 
        {
            case Bot(botHandle):
                if (!isPastGame)
                {
                    botOpponent = BotFactory.build(botHandle);
                    switch ongoingTimeData 
                    {
                        case Some(v):
                            makeBotMove(v);
                        default:
                    }
                }
                chatstack.selectedIndex = 1;
            default:
                chatstack.selectedIndex = 0;
        }

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