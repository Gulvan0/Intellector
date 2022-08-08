package gfx.game;

import gfx.game.GameActionBar.ActionBtn;
import gameboard.GameBoard.GameBoardEvent;
import gameboard.GameBoard.IGameBoardObserver;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import net.EventProcessingQueue.INetObserver;
import net.ServerEvent;
import gfx.game.Clock;
import haxe.ui.containers.Card;
import dict.Phrase;
import gfx.utils.PlyScrollType;
import gfx.common.MoveNavigator;
import haxe.ui.components.Button;
import haxe.ui.util.Color;
import dict.Dictionary;
import js.Browser;
import haxe.ui.containers.HBox;
import struct.Situation;
import struct.Ply;
import haxe.ui.components.VerticalScroll;
import openfl.display.StageAlign;
import haxe.Timer;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import openfl.display.Sprite;
import utils.TimeControl;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/live/sidebox.xml'))
class Sidebox extends VBox implements INetObserver implements IGameBoardObserver //TODO: Maybe get rid of this class at all? (Then maybe we can also remove clock copycat mechanic)
{
    private var orientationColor:PieceColor;
    private var move:Int;  //TODO: do we really need it?

    private var secsPerTurn:Int; //TODO: move to clock
    private var lastMovetableEntry:Dynamic; //TODO: remove completely?

    public function handleNetEvent(event:ServerEvent)
    {
        actionBar.handleNetEvent(event);
        navigator.handleNetEvent(event); //TODO: Clock should be capable of handling such events as well
        switch event 
        {
            case TimeCorrection(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide): //TODO: Remove pingSubtractionSide
                correctTime(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
            case GameEnded(_, _):
                onGameEnded();
            case Rollback(plysToUndo): //TODO: Add time data (also to move)
                revertPlys(plysToUndo);
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        navigator.handleGameBoardEvent(event);
        switch event 
        {
            case ContinuationMove(ply, plyStr, performedBy): //TODO: Server should respond with tcdata
                makeMove(plyStr);
            default:
        }
    }

    private function correctTime(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String)
    {
        var currentTimestamp:Float = Date.now().getTime();
        var halfPing:Float = currentTimestamp - timestamp;

        if (pingSubtractionSide == "w")
            whiteSeconds -= halfPing / 1000;
        else if (pingSubtractionSide == "b")
            blackSeconds -= halfPing / 1000;

        whiteClock.correctTime(whiteSeconds, currentTimestamp);
        blackClock.correctTime(blackSeconds, currentTimestamp);
    }

    private function onGameEnded()
    {
        whiteClock.stopClockCompletely();
        blackClock.stopClockCompletely();
    }

    //===========================================================================================================================================================

    public function revertOrientation()
    {
        setOrientation(opposite(orientationColor));
    }

    private function setOrientation(newOrientationColor:PieceColor)
    {
        if (orientationColor == newOrientationColor)
            return;

        removeComponent(whiteClock, false);
        removeComponent(blackClock, false);
        removeComponent(whiteLoginCard, false);
        removeComponent(blackLoginCard, false);

        orientationColor = newOrientationColor;

        var upperClock:Clock = newOrientationColor == White? blackClock : whiteClock;
        var bottomClock:Clock = newOrientationColor == White? whiteClock : blackClock;
        var upperLogin:Card = newOrientationColor == White? blackLoginCard : whiteLoginCard;
        var bottomLogin:Card = newOrientationColor == White? whiteLoginCard : blackLoginCard;

        addComponentAt(upperLogin, 0);
        addComponentAt(upperClock, 0);

        addComponent(bottomLogin);
        addComponent(bottomClock);
    }

    //========================================================================================================================================================================

    public function makeMove(plyStr:String) 
    {
        move++;
        actionBar.onMoveNumberUpdated(move); //TODO: Why can't actionbar do it on its own?

        whiteClock.onMoveMade(); //TODO: provide args
        blackClock.onMoveMade(); //TODO: provide args
    }

    private function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;

        actionBar.shutAllTakebackRequests(); //TODO: Why can't actionbar do it on its own?
        actionBar.onMoveNumberUpdated(move); //TODO: Why can't actionbar do it on its own?

        whiteClock.onReverted(); //TODO: provide args
        blackClock.onReverted(); //TODO: provide args
    }


    public function new(constructor:LiveGameConstructor, onActionBtnPressed:ActionBtn->Void, onPlyScrollBtnPressed:PlyScrollType->Void, ?orientationColor:PieceColor = White) 
    {
        super();
        setOrientation(orientationColor);
        whiteClock.init(constructor, White);
        blackClock.init(constructor, Black);
        navigator.init(startingSituation.turnColor, onPlyScrollBtnPressed);

        switch constructor 
        {
            case New(whiteLogin, blackLogin, timeControl, startingSituation):
                var playerColor:Null<PieceColor> = LoginManager.isPlayer(whiteLogin)? White : LoginManager.isPlayer(blackLogin)? Black : null;
                whiteLoginLabel.text = whiteLogin;
                blackLoginLabel.text = blackLogin;
                move = 0;
                secsPerTurn = timeControl.bonusSecs;
                actionBar.init(false, playerColor, onActionBtnPressed);
            case Ongoing(parsedData, _), Past(parsedData):
                whiteLoginLabel.text = parsedData.whiteLogin;
                blackLoginLabel.text = parsedData.blackLogin;
                move = parsedData.moveCount;
                secsPerTurn = parsedData.timeControl.bonusSecs;
                actionBar.init(false, parsedData.getPlayerColor(), onActionBtnPressed);
                actionBar.onMoveNumberUpdated(move);
                navigator.actualize(parserOutput.movesPlayedNotation);
        }
    }
}