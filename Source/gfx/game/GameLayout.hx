package gfx.game;

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
import gfx.common.ActionBar.ActionBtn;
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

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game_layout.xml"))
class GameLayout extends VBox implements INetObserver implements IGameBoardObserver
{
    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    private var boardWrapper:BoardWrapper;
    
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var orientationColor:PieceColor = White;

    public static var MIN_SIDEBARS_WIDTH:Float = 150;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    private function performValidation()
    {
        lLeftBox.visible = true;
        lRightBox.visible = true;

        cBlackPlayerHBox.visible = false;
        cWhitePlayerHBox.visible = false;
        cCreepingLine.visible = false;
        cActionBar.visible = false;

        cContentsVBox.percentHeight = 100;

        lContentsHBox.percentWidth = null;
        lContentsHBox.percentHeight = 100;

        lLeftBox.width = MIN_SIDEBARS_WIDTH;
        lRightBox.width = MIN_SIDEBARS_WIDTH;

        boardContainer.percentWidth = null;
        boardContainer.percentHeight = 100;

        boardWrapper.percentHeight = 100;

        cContentsVBox.validateNow();

        if (lContentsHBox.width <= cContentsVBox.width)
        {
            var widthLeft:Float = cContentsVBox.width - lContentsHBox.width;
            lLeftBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft / 2);
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft / 2);
        }
        else
        {
            lLeftBox.visible = false;
            lContentsHBox.validateNow();

            if (lContentsHBox.width <= cContentsVBox.width)
            {
                var widthLeft:Float = cContentsVBox.width - lContentsHBox.width;
                lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft / 2);
            }
            else
            {
                cBlackPlayerHBox.visible = true;
                cWhitePlayerHBox.visible = true;
                cCreepingLine.visible = true;
                cActionBar.visible = true;

                lLeftBox.visible = false;
                lRightBox.visible = false;

                cContentsVBox.percentHeight = null;

                lContentsHBox.percentWidth = 100;
                lContentsHBox.percentHeight = null;

                boardContainer.percentWidth = 100;
                boardContainer.percentHeight = null;

                boardWrapper.percentWidth = 100;
            }
        }
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        performValidation();
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

        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto): //Located in GameLayout since we need board's currentSituation to construct an argument for sidebox
                var ply:Ply = Ply.construct(new IntPoint(fromI, fromJ), new IntPoint(toI, toJ), morphInto == null? null : PieceType.createByName(morphInto));
                sidebox.makeMove(ply.toNotation(board.currentSituation));
            case GameEnded(winner_color, _):
                Assets.getSound("sounds/notify.mp3").play();
                Dialogs.info(Utils.getGameOverPopUpMessage(GameLogParser.decodeOutcome(winner_color), GameLogParser.decodeColor(winner_color), playerColor), Dictionary.getPhrase(GAME_ENDED));
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
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
            case ExportSIP:
                var sip:String = board.shownSituation.serialize();
                Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
            case Analyze:
                if (playerColor == null)
                    Networker.emitEvent(StopSpectate);
                ScreenManager.toScreen(Analysis(board.asVariant().serialize(), null));
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

    //================================================================================================================================================================

    private function revertCompactBarsOrientation() 
    {
        cContentsVBox.removeComponentAt(2, false);
        cContentsVBox.removeComponentAt(0, false);

        orientationColor = opposite(orientationColor);

        var upperBox:HBox = orientationColor == White? cBlackPlayerHBox : cWhitePlayerHBox;
        var lowerBox:HBox = orientationColor == White? cWhitePlayerHBox : cBlackPlayerHBox;

        cContentsVBox.addComponentAt(upperBox, 0);
        cContentsVBox.addComponentAt(lowerBox, 2);
    }

    private function onPlyScrollRequested(type:PlyScrollType)
    {
        cCreepingLine.shiftPointer(type);
        board.applyScrolling(type);
    }

    public static function constructFromActualizationData(actualizationData:ActualizationData, playerColor:Null<PieceColor>, orientationColor:PieceColor):GameLayout
    {
        var timeData:TimeCorrectionData = actualizationData.timeCorrectionData;
        var parserOutput:GameLogParserOutput = actualizationData.logParserOutput;

        var gameLayout:GameLayout = new GameLayout();

        gameLayout.board = buildBoard(parserOutput.currentSituation, playerColor, orientationColor);
        gameLayout.sidebox = Sidebox.constructFromActualizationData(actualizationData, orientationColor, gameLayout.handleActionBtnPress, gameLayout.onPlyScrollRequested);
        gameLayout.chatbox = Chatbox.constructFromActualizationData(playerColor == null, actualizationData);
        gameLayout.gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        gameLayout.performCommonInitSteps(parserOutput.whiteLogin, parserOutput.blackLogin, parserOutput.timeControl, playerColor);

        return gameLayout;
    }

    public static function constructFromParams(whiteLogin:String, blackLogin:String, orientationColor:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>):GameLayout 
    {
        var gameLayout:GameLayout = new GameLayout();

        gameLayout.board = buildBoard(Situation.starting(), playerColor, orientationColor);
        gameLayout.sidebox = new Sidebox(playerColor, timeControl, whiteLogin, blackLogin, orientationColor, gameLayout.handleActionBtnPress, gameLayout.onPlyScrollRequested);
        gameLayout.chatbox = new Chatbox(playerColor == null);
        gameLayout.gameinfobox = new GameInfoBox(timeControl, whiteLogin, blackLogin);

        gameLayout.performCommonInitSteps(whiteLogin, blackLogin, timeControl, playerColor);

        return gameLayout;
    }

    private function performCommonInitSteps(whiteLogin:String, blackLogin:String, timeControl:TimeControl, playerColor:PieceColor)
    {
        this.playerColor = playerColor;

        board.addObserver(this);

        boardWrapper = new BoardWrapper(board);

        lLeftBox.addComponent(gameinfobox);
        lLeftBox.addComponent(chatbox);
        lRightBox.addComponent(sidebox);
        boardContainer.addComponent(boardWrapper);

        cWhiteLogin.text = whiteLogin;
        cBlackLogin.text = blackLogin;

        cWhiteClock.resize(30);
        cBlackClock.resize(30);

        sidebox.whiteClock.addCopycat(cWhiteClock);
        sidebox.blackClock.addCopycat(cBlackClock);

        cWhiteClock.init(timeControl.startSecs, playerColor == White, timeControl.startSecs >= 90, true);
        cBlackClock.init(timeControl.startSecs, playerColor == Black, timeControl.startSecs >= 90, false);
        cCreepingLine.init(board.scrollToMove);
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
    }
}