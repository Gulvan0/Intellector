package tests.ui.game;

import tests.ui.TestedComponent;
import net.LoginManager;
import struct.ActualizationData;
import utils.TimeControl;
import net.ServerEvent;
import struct.PieceColor;
import struct.Situation;
import struct.Ply;
import serialization.PlySerializer;
import js.Browser;
import gameboard.GameBoard.GameBoardEvent;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.game.Sidebox;
import openfl.display.Sprite;
import tests.ui.ArgumentType;

class TSidebox extends TestedComponent
{
    private var sidebox:Sidebox;
    private var previousSituations:Array<Situation> = [];
    private var situation:Situation;

    private var _paramvalues_timeControl = [new TimeControl(80, 5), new TimeControl(100, 5), new TimeControl(600, 5)];
    private var _initparam_timeControl:TimeControl = new TimeControl(600, 5);

    private var _paramvalues_whiteLogin = ["Al", "ra", "Gulvan", "kartoved", "wswswswswswswswswsws", "SwsWswSwsWswSwsWswSW"];
    private var _initparam_whiteLogin:String = "Gulvan";

    private var _paramvalues_blackLogin = ["Al", "ra", "Gulvan", "kartoved", "wswswswswswswswswsws", "SwsWswSwsWswSwsWswSW"];
    private var _initparam_blackLogin:String = "kartoved";

    private var _paramvalues_playerColor = [White, Black, null];
    private var _initparam_playerColor:Null<PieceColor> = White;

    private var _initparam_orientationColor:PieceColor = White;

    private var _paramvalues_actualizationMoveCnt = [0, 1, 2, 3, 4];
    private var _initparam_actualizationMoveCnt:Int = 0;

    public override function _provide_situation():Situation
    {
        return situation;
    }

    @prompt("APly", "Move")
    private function _act_continuationMove(ply:Ply) 
    {
        var plyStr:String = ply.toNotation(situation);
        var performedBy:PieceColor = situation.get(ply.from).color;
        sidebox.handleGameBoardEvent(ContinuationMove(ply, plyStr, performedBy));
        previousSituations.push(situation.copy());
        situation.makeMove(ply, true);
    }

    private function _act_fillGame() 
    {
        var turnColor:PieceColor = situation.turnColor;
        for (plyInfo in situation.randomContinuation(25))
        {
            sidebox.handleGameBoardEvent(ContinuationMove(plyInfo.ply, plyInfo.plyStr, turnColor));
            turnColor = opposite(turnColor);
            previousSituations.push(situation.copy());
            situation.makeMove(plyInfo.ply, true);
        }
    }
    
    @prompt("AEnumerable", "Event name", ["DrawOffered", "DrawCancelled", "DrawAccepted", "DrawDeclined", "TakebackOffered", "TakebackCancelled", "TakebackAccepted", "TakebackDeclined"])
    private function _act_offerEvent(event:String) 
    {
        sidebox.handleNetEvent(ServerEvent.createByName(event));
    }

    private function _act_gameEnded() 
    {
        sidebox.handleNetEvent(GameEnded('w', 'mat'));
    }

    private function _act_rollbackThree() 
    {
        sidebox.handleNetEvent(Rollback(3));
        previousSituations.pop();
        previousSituations.pop();
        situation = previousSituations.pop();
    }

    private function _act_correctTime() 
    {
        var ts = Date.now().getTime() - 200;
        sidebox.handleNetEvent(TimeCorrection(124, 9, ts, 'b'));
    }

    private override function getComponent():ComponentGraphics
    {
		return Component(sidebox);
    }

    private override function rebuildComponent()
    {
        var logLogins = '$_initparam_whiteLogin:$_initparam_blackLogin';
        var logTime = _initparam_timeControl.startSecs + "/" + _initparam_timeControl.bonusSecs;
        var logPreamble = '#P|$logLogins;\n#T|$logTime;\n';

        if (_initparam_playerColor == White)
            LoginManager.login = _initparam_whiteLogin;
        else if (_initparam_playerColor == Black)
            LoginManager.login = _initparam_blackLogin;
        else
            LoginManager.login = "##nobody##";

        previousSituations = [];
        situation = Situation.starting();

        if (_initparam_actualizationMoveCnt == 0)
            sidebox = new Sidebox(_initparam_playerColor, _initparam_timeControl, _initparam_whiteLogin, _initparam_blackLogin, _initparam_orientationColor, ab -> {output(ab.getName());}, ps -> {output(ps.getName());});
        else 
        {
            var log:String;
            if (_initparam_actualizationMoveCnt == 1)
                log = logPreamble;
            else if (_initparam_actualizationMoveCnt == 2)
                log = logPreamble + "6620;\n";
            else if (_initparam_actualizationMoveCnt == 3)
                log = logPreamble + "6620;\n3020Aggressor;\n";
            else
                log = logPreamble + "6620;\n3020Aggressor;\n1514;\n";

            var data:ActualizationData = new ActualizationData(log);
            sidebox = Sidebox.constructFromActualizationData(data, _initparam_orientationColor, ab -> {output(ab.getName());}, ps -> {output(ps.getName());});

            for (ply in data.logParserOutput.movesPlayed)
            {
                previousSituations.push(situation.copy());
                situation.makeMove(ply, true);
            }
        }
    }
}