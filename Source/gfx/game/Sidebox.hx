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
import struct.ActualizationData;
import utils.TimeControl;
using utils.CallbackTools;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/live/sidebox.xml'))
class Sidebox extends VBox implements INetObserver implements IGameBoardObserver
{
    private var orientationColor:PieceColor;
    private var move:Int;

    private var secsPerTurn:Int;
    private var lastMovetableEntry:Dynamic;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case TimeCorrection(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide):
                correctTime(whiteSeconds, blackSeconds, timestamp, pingSubtractionSide);
            case GameEnded(_, _):
                onGameEnded();
            case Rollback(plysToUndo):
                revertPlys(plysToUndo);
            default:
        }
        actionBar.handleNetEvent(event);
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(ply, plyStr, performedBy):
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
        removeComponent(whiteClock, false);
        removeComponent(blackClock, false);
        removeComponent(whiteLoginCard, false);
        removeComponent(blackLoginCard, false);

        orientationColor = opposite(orientationColor);

        var upperClock:Clock = orientationColor == White? blackClock : whiteClock;
        var bottomClock:Clock = orientationColor == White? whiteClock : blackClock;
        var upperLogin:Card = orientationColor == White? blackLoginCard : whiteLoginCard;
        var bottomLogin:Card = orientationColor == White? whiteLoginCard : blackLoginCard;

        addComponentAt(upperLogin, 0);
        addComponentAt(upperClock, 0);

        addComponent(bottomLogin);
        addComponent(bottomClock);
    }

    //========================================================================================================================================================================

    public function makeMove(plyStr:String) 
    {
        move++;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? whiteClock : blackClock;

        justMovedPlayerClock.pauseTimer();
        justMovedPlayerClock.setPlayerMove(false);
        playerToMoveClock.setPlayerMove(true);

        if (move >= 2)
            playerToMoveClock.launchTimer();

        if (move >= 3)
            justMovedPlayerClock.addTime(secsPerTurn);

        navigator.writePlyStr(plyStr, true);
        navigator.scrollAfterDelay();

        actionBar.onMoveNumberUpdated(move);
    }

    private function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? whiteClock : blackClock;

        if (cnt % 2 == 1)
        {
            justMovedPlayerClock.pauseTimer();
            justMovedPlayerClock.setPlayerMove(false);
            playerToMoveClock.setPlayerMove(true);
            playerToMoveClock.launchTimer();
        }

        actionBar.shutAllTakebackRequests();
        actionBar.onMoveNumberUpdated(move);

        navigator.revertPlys(cnt);
        navigator.scrollAfterDelay();
    }

    public static function constructFromActualizationData(data:ActualizationData, orientationColor:PieceColor, onActionBtnPressed:ActionBtn->Void, onPlyScrollBtnPressed:PlyScrollType->Void):Sidebox
    {
        var playingAs:Null<PieceColor> = data.logParserOutput.getPlayerColor();
        var timeControl:TimeControl = data.logParserOutput.timeControl;
        var whiteLogin:String = data.logParserOutput.whiteLogin;
        var blackLogin:String = data.logParserOutput.blackLogin;

        var sidebox:Sidebox = new Sidebox(playingAs, timeControl, whiteLogin, blackLogin, orientationColor, onActionBtnPressed, onPlyScrollBtnPressed);

        var situation:Situation = Situation.starting();
        for (ply in data.logParserOutput.movesPlayed)
        {
            sidebox.makeMove(ply.toNotation(situation));
            situation = situation.makeMove(ply);
        }

        if (data.timeCorrectionData != null)
            sidebox.correctTime(data.timeCorrectionData.whiteSeconds, data.timeCorrectionData.blackSeconds, data.timeCorrectionData.timestamp, data.timeCorrectionData.pingSubtractionSide);

        return sidebox;
    }

    public function new(playingAs:Null<PieceColor>, timeControl:TimeControl, whiteLogin:String, blackLogin:String, orientationColor:PieceColor, onActionBtnPressed:ActionBtn->Void, onPlyScrollBtnPressed:PlyScrollType->Void) 
    {
        super();
        this.secsPerTurn = timeControl.bonusSecs;
        this.orientationColor = White;
        this.move = 0;
        
        whiteClock.init(timeControl.startSecs, playingAs == White, timeControl.startSecs >= 90, true);
        blackClock.init(timeControl.startSecs, playingAs == Black, timeControl.startSecs >= 90, false);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;
        
        navigator.init(White, onPlyScrollBtnPressed);
        actionBar.init(false, playingAs, onActionBtnPressed);

        if (orientationColor == Black)
            revertOrientation();
    }
}