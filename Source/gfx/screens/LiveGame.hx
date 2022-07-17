package gfx.screens;

import gfx.game.*;
import haxe.ui.core.Component;
import net.GeneralObserver;
import utils.MathUtils;
import haxe.ui.core.Screen;
import browser.URLEditor;
import struct.Outcome;
import serialization.PortableIntellectorNotation;
import gfx.common.ShareDialog;
import openfl.events.Event;
import haxe.Timer;
import serialization.GameLogParser;
import dict.Utils;
import gfx.components.Dialogs;
import openfl.Assets;
import struct.IntPoint;
import net.ServerEvent;
import js.Browser;
import dict.Dictionary;
import net.EventProcessingQueue.INetObserver;
import serialization.GameLogParser.GameLogParserOutput;
import struct.Variant;
import struct.Ply;
import gfx.utils.PlyScrollType;
import gfx.game.GameActionBar.ActionBtn;
import haxe.ui.containers.HBox;
import gfx.components.BoardWrapper;
import struct.Situation;
import gameboard.behaviors.EnemyMoveBehavior;
import gameboard.behaviors.PlayerMoveBehavior;
import gameboard.behaviors.StubBehavior;
import gameboard.behaviors.IBehavior;
import gameboard.GameBoard;
import utils.TimeControl;
import struct.ActualizationData;
import struct.PieceColor;
import haxe.exceptions.NotImplementedException;
import haxe.ui.containers.VBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/live_layout.xml"))
class LiveGame extends HBox implements INetObserver implements IGameBoardObserver implements IScreen
{
    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    private var boardWrapper:BoardWrapper;
    
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var orientationColor:PieceColor = White;

    private var whiteLogin:String;
    private var blackLogin:String;
    private var timeControl:TimeControl;
    private var winnerColor:Null<PieceColor> = null;
    private var outcome:Null<Outcome> = null;

    public static var MIN_SIDEBARS_WIDTH:Float = 200;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    private var renderedForWidth:Float = 0;
    private var renderedForHeight:Float = 0;

    public function onEntered()
    {
        GeneralObserver.acceptsDirectChallenges = false;
        Networker.eventQueue.addObserver(this);
		Assets.getSound("sounds/notify.mp3").play();
    }

    public function onClosed()
    {
        Networker.eventQueue.removeObserser(this);
        GeneralObserver.acceptsDirectChallenges = true;
    }

    public function menuHidden():Bool
    {
        return false;
    }

    public function asComponent():Component
    {
        return this;
    }

    //Please don't hate me for this. Responsive layout design is a pain
    private function performValidation()
    {
        var compact:Bool = Screen.instance.width * 6 < Screen.instance.height * 7;
        var largeBoardMaxWidth:Float = Screen.instance.height / boardWrapper.inverseAspectRatio();
        var bothBarsVisible:Bool = Screen.instance.width < largeBoardMaxWidth + 2 * MIN_SIDEBARS_WIDTH;

        cBlackPlayerHBox.hidden = !compact;
        cWhitePlayerHBox.hidden = !compact;
        cActionBar.hidden = !compact;
        cCreepingLine.hidden = !compact;

        lLeftBox.hidden = compact || bothBarsVisible;
        lRightBox.hidden = compact;

        if (bothBarsVisible)
        {
            lLeftBox.width = Math.min(MAX_SIDEBARS_WIDTH, (Screen.instance.width - largeBoardMaxWidth) / 2);
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, (Screen.instance.width - largeBoardMaxWidth) / 2);
        }
        else
            lRightBox.width = MathUtils.clamp(Screen.instance.width - largeBoardMaxWidth, MIN_SIDEBARS_WIDTH, MAX_SIDEBARS_WIDTH);
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();

        if (renderedForWidth != Screen.instance.width || renderedForHeight != Screen.instance.height)
        {
            performValidation();
            renderedForWidth = Screen.instance.width;
            renderedForHeight = Screen.instance.height;
            return true;
        }

        return b;
    }

    //================================================================================================================================================================

    public function handleNetEvent(event:ServerEvent)
    {
        board.handleNetEvent(event);
        gameinfobox.handleNetEvent(event);
        chatbox.handleNetEvent(event);
        sidebox.handleNetEvent(event);
        cActionBar.handleNetEvent(event);
        cCreepingLine.handleNetEvent(event);

        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto): //Located in LiveGame since we need board's currentSituation to construct an argument for sidebox
                var ply:Ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto == null? null : PieceType.createByName(morphInto));
                sidebox.makeMove(ply.toNotation(board.currentSituation));
            case GameEnded(winnerColorCode, outcomeCode):
                winnerColor = GameLogParser.decodeColor(winnerColorCode);
                outcome = GameLogParser.decodeOutcome(outcomeCode);
                Assets.getSound("sounds/notify.mp3").play();
                Dialogs.info(Utils.getGameOverPopUpMessage(outcome, winnerColor, playerColor), Dictionary.getPhrase(GAME_ENDED));
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        cCreepingLine.handleGameBoardEvent(event);
        sidebox.handleGameBoardEvent(event);

        switch event 
        {
            case ContinuationMove(ply, _, _):
                Networker.emitEvent(Move(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto.getName()));
            default:
        }
    }

    public function handleActionBtnPress(btn:ActionBtn)
    {
        switch btn 
        {
            case Resign:
                Networker.emitEvent(Resign);
            case ChangeOrientation:
                board.revertOrientation();
                sidebox.revertOrientation();
                revertCompactBarsOrientation();
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
                Networker.emitEvent(Rematch);
            case Share:
                var gameLink:String = URLEditor.getGameLink(ScreenManager.getViewedGameID());
                var playedMoves:Array<Ply> = board.plyHistory.getPlySequence();
                //TODO: Pass DateTime instead of null
                var pin:String = PortableIntellectorNotation.serialize(playedMoves, whiteLogin, blackLogin, timeControl, null, outcome, winnerColor);

                var shareDialog:ShareDialog = new ShareDialog();
                shareDialog.initInGame(board.shownSituation, board.orientationColor, gameLink, pin, playedMoves);
                shareDialog.showShareDialog(board);
            case Analyze:
                if (playerColor == null)
                    Networker.emitEvent(StopSpectate);
                ScreenManager.toScreen(Analysis(getSerializedVariant(), null, null));
            case AcceptDraw:
                Networker.emitEvent(AcceptDraw);
            case DeclineDraw:
                Networker.emitEvent(DeclineDraw);
            case AcceptTakeback:
                Networker.emitEvent(AcceptTakeback);
            case DeclineTakeback:
                Networker.emitEvent(DeclineTakeback);
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

    private function revertCompactBarsOrientation() 
    {
        centerBox.removeComponentAt(2, false);
        centerBox.removeComponentAt(0, false);

        orientationColor = opposite(orientationColor);

        var upperBox:HBox = orientationColor == White? cBlackPlayerHBox : cWhitePlayerHBox;
        var lowerBox:HBox = orientationColor == White? cWhitePlayerHBox : cBlackPlayerHBox;

        centerBox.addComponentAt(upperBox, 0);
        centerBox.addComponentAt(lowerBox, 2);
    }

    private function onPlyScrollRequested(type:PlyScrollType)
    {
        cCreepingLine.shiftPointer(type);
        board.applyScrolling(type);
    }

    public static function constructFromActualizationData(actualizationData:ActualizationData, ?orientationColor:PieceColor):LiveGame
    {
        var timeData:TimeCorrectionData = actualizationData.timeCorrectionData;
        var parserOutput:GameLogParserOutput = actualizationData.logParserOutput;
        var playerColor:Null<PieceColor> = actualizationData.logParserOutput.getPlayerColor();

        if (orientationColor == null)
            if (playerColor == null)
                orientationColor = White;
            else
                orientationColor = playerColor;

        var screen:LiveGame = new LiveGame();

        screen.board = buildBoard(parserOutput.currentSituation, playerColor, orientationColor);
        screen.sidebox = Sidebox.constructFromActualizationData(actualizationData, orientationColor, screen.handleActionBtnPress, screen.onPlyScrollRequested);
        screen.chatbox = Chatbox.constructFromActualizationData(playerColor == null, actualizationData);
        screen.gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        screen.performCommonInitSteps(parserOutput.whiteLogin, parserOutput.blackLogin, parserOutput.timeControl, playerColor);

        return screen;
    }

    public static function constructFromParams(whiteLogin:String, blackLogin:String, orientationColor:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>):LiveGame 
    {
        var screen:LiveGame = new LiveGame();

        screen.board = buildBoard(Situation.starting(), playerColor, orientationColor);
        screen.sidebox = new Sidebox(playerColor, timeControl, whiteLogin, blackLogin, orientationColor, screen.handleActionBtnPress, screen.onPlyScrollRequested);
        screen.chatbox = new Chatbox(playerColor == null);
        screen.gameinfobox = new GameInfoBox(timeControl, whiteLogin, blackLogin);

        screen.performCommonInitSteps(whiteLogin, blackLogin, timeControl, playerColor);

        return screen;
    }

    private function performCommonInitSteps(whiteLogin:String, blackLogin:String, timeControl:TimeControl, playerColor:PieceColor)
    {
        this.playerColor = playerColor;
        this.whiteLogin = whiteLogin;
        this.blackLogin = blackLogin;
        this.timeControl = timeControl;

        board.addObserver(this);

        boardWrapper = new BoardWrapper(board);
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;

        lLeftBox.addComponent(gameinfobox);
        lLeftBox.addComponent(chatbox);
        lRightBox.addComponent(sidebox);
        boardContainer.addComponent(boardWrapper);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;

        sidebox.whiteClock.addCopycat(whiteClock);
        sidebox.blackClock.addCopycat(blackClock);

        whiteClock.init(timeControl.startSecs, playerColor == White, timeControl.startSecs >= 90, true);
        blackClock.init(timeControl.startSecs, playerColor == Black, timeControl.startSecs >= 90, false);
        cCreepingLine.init(i -> {
            board.applyScrolling(Precise(i));
            cCreepingLine.setPointer(i);
            sidebox.navigator.setPointer(i);
        });
        cActionBar.init(true, playerColor, handleActionBtnPress);

        if (orientationColor == Black)
            revertCompactBarsOrientation();
    }

    private static function buildBoard(currentSituation:Situation, playerColor:PieceColor, orientationColor:PieceColor)
    {
        var behavior:IBehavior;
        if (playerColor == null)
            behavior = new StubBehavior();
        else if (currentSituation.turnColor == playerColor)
            behavior = new PlayerMoveBehavior(playerColor);
        else
            behavior = new EnemyMoveBehavior(playerColor);

        return new GameBoard(currentSituation, orientationColor, behavior, playerColor == null);
    }

    private function new() 
    {
        super(); 
        whiteClock.resize(30);
        blackClock.resize(30);
    }
}