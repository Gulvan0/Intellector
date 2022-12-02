package tests.ui.game;

import tests.ui.TestedComponent;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Slider;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import gfx.screens.LiveGame;
import haxe.ui.containers.Box;
import serialization.GameLogParser.GameLogParserOutput;
import haxe.Timer;
import utils.TimeControl;
import gfx.game.GameInfoBox;
import openfl.display.Sprite;

class TGameInfoBox extends TestedComponent
{
    private var gameinfobox:GameInfoBox;
    private var previousSituations:Array<Situation> = [];
    private var playthrough_sit:Situation;

    private var _paramvalues_timeControl = [new TimeControl(0, 0), new TimeControl(15, 1), new TimeControl(60, 1), new TimeControl(180, 2), new TimeControl(600, 0), new TimeControl(3600, 0)];
    private var _initparam_timeControl:TimeControl = new TimeControl(600, 0);

    private var _paramvalues_whiteLogin = ["Al", "ra", "Gulvan", "kartoved", "wswswswswswswswswsws", "SwsWswSwsWswSwsWswSW"];
    private var _initparam_whiteLogin:String = "Gulvan";

    private var _paramvalues_blackLogin = ["Al", "ra", "Gulvan", "kartoved", "wswswswswswswswswsws", "SwsWswSwsWswSwsWswSW"];
    private var _initparam_blackLogin:String = "kartoved";

    private var _initparam_actualization:Bool = false;

    public override function _provide_situation():Situation
    {
        return playthrough_sit;
    }

    @iterations(3)
    private function _seq_playthrough(i:Int) 
    {
        if (i == 0)
            update();

        var plyInfo = playthrough_sit.randomContinuation(1)[0];
        if (i % 2 == 1)
            gameinfobox.handleGameBoardEvent(ContinuationMove(plyInfo.ply, plyInfo.plyStr, Black));
        else
            gameinfobox.handleNetEvent(Move(plyInfo.ply.from.i, plyInfo.ply.to.i, plyInfo.ply.from.j, plyInfo.ply.to.j, plyInfo.ply.morphInto));
        
        previousSituations.push(playthrough_sit.copy());
        playthrough_sit.makeMove(plyInfo.ply, true);
    }

    private function _act_rollback() 
    {
        gameinfobox.handleNetEvent(Rollback(1));
        playthrough_sit = previousSituations.pop();
    }

    @iterations(14)
    private function _seq_seeResolutions(i:Int) 
    {
        if (i == 0)
            update();

        var decisiveOutcomes:Array<String> = ['mat', 'bre', 'res', 'aba', 'tim'];
        var drawishOutcomes:Array<String> = ['agr', 'rep', '100', 'abo'];
        if (i < decisiveOutcomes.length * 2)
        {
            var winner = i % 2 == 0? 'w' : 'b';
            var outcome = decisiveOutcomes[Math.floor(i/2)];
            gameinfobox.handleNetEvent(GameEnded(winner, outcome));
        }
        else
            gameinfobox.handleNetEvent(GameEnded('d', drawishOutcomes[i - decisiveOutcomes.length * 2]));
    }

    private override function getComponent():ComponentGraphics
    {
		return AdjustableContent(gameinfobox, LiveGame.MIN_SIDEBARS_WIDTH, LiveGame.MAX_SIDEBARS_WIDTH, -1, -1);
    }

    private override function rebuildComponent()
    {
        previousSituations = [];
        playthrough_sit = Situation.starting();

        if (!_initparam_actualization)
        {
            gameinfobox = new GameInfoBox(_initparam_timeControl, _initparam_whiteLogin, _initparam_blackLogin);
            return;
        }
        
        var po:GameLogParserOutput = new GameLogParserOutput();
        po.whiteLogin = _initparam_whiteLogin;
        po.blackLogin = _initparam_blackLogin;
        po.datetime = Date.now();
        po.timeControl = _initparam_timeControl;
        po.movesPlayed = [Ply.construct(new IntPoint(1, 5), new IntPoint(1, 3)), Ply.construct(new IntPoint(1, 0), new IntPoint(1, 2))];
        po.outcome = Resign;
        po.winnerColor = Black;

        var actualizationData:ActualizationData = new ActualizationData();
        actualizationData.logParserOutput = po;

        gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        for (ply in po.movesPlayed)
        {
            previousSituations.push(playthrough_sit.copy());
            playthrough_sit.makeMove(ply, true);
        }
    }
}