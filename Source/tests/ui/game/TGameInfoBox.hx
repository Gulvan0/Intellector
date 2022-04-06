package tests.ui.game;

import struct.IntPoint;
import struct.Ply;
import serialization.GameLogParser.GameLogParserOutput;
import struct.Situation;
import haxe.Timer;
import utils.TimeControl;
import gfx.game.GameInfoBox;
import openfl.display.Sprite;

class TGameInfoBox extends Sprite
{
    private var gameinfobox:GameInfoBox;

    private function setBox(v:GameInfoBox)
    {
        removeChild(gameinfobox);
        gameinfobox = v;
        addChild(gameinfobox);
    }

    @interval(1000)
    @iterations(6)
    private function _auto_varyTimeControls(i:Int) 
    {
        switch i
        {
            case 0:
                setBox(new GameInfoBox(new TimeControl(0, 0), "Gulvan", "kartoved"));
            case 1:
                setBox(new GameInfoBox(new TimeControl(15, 1), "Gulvan", "kartoved"));
            case 2:
                setBox(new GameInfoBox(new TimeControl(60, 1), "Gulvan", "kartoved"));
            case 3:
                setBox(new GameInfoBox(new TimeControl(180, 2), "Gulvan", "kartoved"));
            case 4:
                setBox(new GameInfoBox(new TimeControl(600, 0), "Gulvan", "kartoved"));
            case 5:
                setBox(new GameInfoBox(new TimeControl(3600, 0), "Gulvan", "kartoved"));
        }
    }

    @interval(1000)
    @iterations(4)
    private function _auto_varyNames(i:Int) 
    {
        switch i
        {
            case 0:
                setBox(new GameInfoBox(new TimeControl(3, 0), "Al", "ra"));
            case 1:
                setBox(new GameInfoBox(new TimeControl(3, 0), "wswswswswswswswswsws", "swswswswswswswswswsw"));
            case 2:
                setBox(new GameInfoBox(new TimeControl(3, 0), "Al", "swswswswswswswswswsw"));
            case 3:
                setBox(new GameInfoBox(new TimeControl(3, 0), "swswswswswswswswswsw", "ra"));
        }
    }

    private var playthrough_sit:Situation;

    @interval(1000)
    @iterations(3)
    private function _auto_playthrough(i:Int) 
    {
        if (i == 0)
            playthrough_sit = Situation.starting();

        var plyInfo = playthrough_sit.randomContinuation(1)[0];
        if (i % 2 == 1)
            gameinfobox.handleGameBoardEvent(ContinuationMove(plyInfo.ply, plyInfo.plyStr, Black));
        else
            gameinfobox.handleNetEvent(Move(plyInfo.ply.from.i, plyInfo.ply.to.i, plyInfo.ply.from.j, plyInfo.ply.to.j, plyInfo.ply.morphInto == null? null : plyInfo.ply.morphInto.getName()));
        playthrough_sit.makeMove(plyInfo.ply, true);
    }

    private function _act_rollback() 
    {
        gameinfobox.handleNetEvent(Rollback(1));
    }

    private function _act_seeResolutions() 
    {
        var decisiveOutcomes:Array<String> = ['mat', 'bre', 'res', 'aba', 'tim'];
        var drawishOutcomes:Array<String> = ['agr', 'rep', '100', 'abo'];
        var i:Int = 0;
        var t:Timer = new Timer(1000);
        t.run = () -> {
            if (i < decisiveOutcomes.length * 2)
            {
                var winner = i % 2 == 0? 'w' : 'b';
                var outcome = decisiveOutcomes[Math.floor(i/2)];
                gameinfobox.handleNetEvent(GameEnded(winner, outcome));
            }
            else if (i < decisiveOutcomes.length * 2 + drawishOutcomes.length)
                gameinfobox.handleNetEvent(GameEnded('d', drawishOutcomes[i - decisiveOutcomes.length * 2]));
            else
                t.stop();
            i++;
        };
    }

    private function _act_testActualization() 
    {
        var actualizationData:GameLogParserOutput = new GameLogParserOutput();
        actualizationData.whiteLogin = "Gulvan";
        actualizationData.blackLogin = "kartoved";
        actualizationData.timeControl = new TimeControl(360, 2);
        actualizationData.movesPlayed = [Ply.construct(new IntPoint(1, 5), new IntPoint(1, 3)), Ply.construct(new IntPoint(1, 0), new IntPoint(1, 2))];
        actualizationData.outcome = Resign;
        actualizationData.winnerColor = Black;
        setBox(new GameInfoBox(null, "Gulvan", "kartoved", actualizationData));
    }

    private var _checks_testActualization:Array<String> = [
        "Pillar opening",
        "3+2 Time control",
        "White resigned"
    ];

    public function new() 
    {
        super();
        gameinfobox = new GameInfoBox(new TimeControl(600, 0), "Al", "ra");
        addChild(gameinfobox);
    }
}