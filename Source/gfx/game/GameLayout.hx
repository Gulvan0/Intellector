package gfx.game;

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

    public static var MIN_SIDEBARS_WIDTH:Float = 200;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    private var renderedForWidth:Float = 0;
    private var renderedForHeight:Float = 0;
    private var validationTimer:Timer;

    //Please don't hate me for this. Responsive layout design is a pain
    private function performValidation()
    {
        //By default, show desktop mode components
        cBlackPlayerHBox.hidden = true;
        cWhitePlayerHBox.hidden = true;
        cCreepingLine.hidden = true;
        cActionBar.hidden = true;

        lLeftBox.hidden = false;
        lRightBox.hidden = false;

        //Try to estimate how much width will we need if both left (gameinfobox, chatbox) and right (sidebox) boxes are shown
        var estimatedGameboardWidth = this.height / boardWrapper.inverseAspectRatio();
        var hboxWidth = 2 * MIN_SIDEBARS_WIDTH + estimatedGameboardWidth + lContentsHBox.style.horizontalSpacing * 2;

        //If we have enough screen width...
        if (hboxWidth <= this.width)
        {
            //We can use the remaining space to increase the width of boxes, but not higher than MAX_SIDEBARS_WIDTH
            var widthLeft:Float = this.width - hboxWidth;
            lLeftBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft / 2);
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft / 2);

            //Scale everything based on height

            cContentsVBox.percentWidth = 100;
            cContentsVBox.percentHeight = 100;

            lContentsHBox.percentWidth = null;
            lContentsHBox.percentHeight = 100;

            boardContainer.percentWidth = null;
            boardContainer.percentHeight = 100;

            boardWrapper.percentWidth = null;
            boardWrapper.percentHeight = 100;

            return;
        }

        //Since we don't have enough width, maybe we can fit everything by hiding the left box?
        hboxWidth = MIN_SIDEBARS_WIDTH + estimatedGameboardWidth + lContentsHBox.style.horizontalSpacing;

        //If we can...
        if (hboxWidth <= this.width)
        {
            //Analogically, use the remaining space to increase the width
            var widthLeft:Float = this.width - hboxWidth;
            lLeftBox.hidden = true; //The left box is now hidden, ...
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, MIN_SIDEBARS_WIDTH + widthLeft); //...thus, only stretch the right one

            //Analogically, scale everything based on height

            cContentsVBox.percentWidth = 100;
            cContentsVBox.percentHeight = 100;

            lContentsHBox.percentWidth = null;
            lContentsHBox.percentHeight = 100;

            boardContainer.percentWidth = null;
            boardContainer.percentHeight = 100;

            boardWrapper.percentWidth = null;
            boardWrapper.percentHeight = 100;

            return;
        }

        //If we can't fit everything using the desktop layout anyway, use the mobile layout

        //Display only the components relevant for the mobile layout
        lLeftBox.hidden = true;
        lRightBox.hidden = true;

        cBlackPlayerHBox.hidden = false;
        cWhitePlayerHBox.hidden = false;
        cCreepingLine.hidden = false;
        cActionBar.hidden = false;

        //Try to fit everything provided the gameboard's width is equal to the screen's width
        var estimatedGameboardHeight = this.width * boardWrapper.inverseAspectRatio();
        var availableHeight = this.height - this.style.verticalSpacing - cCreepingLine.runwaySV.height;
        var vBoxHeight = estimatedGameboardHeight + cContentsVBox.style.verticalSpacing * 3 + 35 + 30 * 2;

        if (vBoxHeight <= availableHeight) //If we can, use 100% of the screen's width
        {
            cContentsVBox.percentWidth = 100;
            cContentsVBox.percentHeight = null;

            lContentsHBox.percentWidth = 100;
            lContentsHBox.percentHeight = null;

            boardContainer.percentWidth = 100;
            boardContainer.percentHeight = null;

            boardWrapper.percentHeight = null;
            boardWrapper.percentWidth = 100;
        }
        else //Otherwise, use 100% of the screen's height
        {
            cContentsVBox.percentWidth = null;
            cContentsVBox.percentHeight = 100;

            lContentsHBox.percentWidth = null;
            lContentsHBox.percentHeight = 100;

            boardContainer.percentWidth = null;
            boardContainer.percentHeight = 100;

            boardWrapper.percentWidth = null;
            boardWrapper.percentHeight = 100;
        }
    }

    private function ownValidation() 
    {
        if (renderedForWidth != Browser.window.innerWidth || renderedForHeight != Browser.window.innerHeight)
        {
            performValidation();
            Timer.delay(performValidation, 200);
        }
        renderedForWidth = Browser.window.innerWidth;
        renderedForHeight = Browser.window.innerHeight;
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

    private function onAdded(e)
    {
        removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        performValidation();
        validationTimer = new Timer(100);
        validationTimer.run = ownValidation;
        addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
    }

    private function onRemoved(e)
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        if (validationTimer != null)
            validationTimer.stop();
    }

    private function new() 
    {
        super(); 
        cWhiteClock.resize(30);
        cBlackClock.resize(30);
        addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }
}