package tests.ui.game;

import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Slider;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import gfx.game.GameLayout;
import haxe.ui.containers.Box;
import struct.ActualizationData;
import struct.IntPoint;
import struct.Ply;
import serialization.GameLogParser.GameLogParserOutput;
import struct.Situation;
import haxe.Timer;
import utils.TimeControl;
import gfx.game.GameInfoBox;
import openfl.display.Sprite;

class TGameInfoBox extends VBox
{
    private var container:Box;
    private var gameinfobox:GameInfoBox;

    private function setBox(v:GameInfoBox)
    {
        container.removeComponent(gameinfobox);
        gameinfobox = v;
        gameinfobox.horizontalAlign = 'center';
        gameinfobox.verticalAlign = 'center';
        container.addComponent(gameinfobox);
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
        var po:GameLogParserOutput = new GameLogParserOutput();
        po.whiteLogin = "Gulvan";
        po.blackLogin = "kartoved";
        po.datetime = Date.now();
        po.timeControl = new TimeControl(360, 2);
        po.movesPlayed = [Ply.construct(new IntPoint(1, 5), new IntPoint(1, 3)), Ply.construct(new IntPoint(1, 0), new IntPoint(1, 2))];
        po.outcome = Resign;
        po.winnerColor = Black;

        var actualizationData:ActualizationData = new ActualizationData();
        actualizationData.logParserOutput = po;
        setBox(GameInfoBox.constructFromActualizationData(actualizationData));
    }

    private var _checks_testActualization:Array<String> = [
        "Pillar opening",
        "3+2 Time control",
        "White resigned",
        "DateTime displayed correctly",
        "Test resolutions after this"
    ];

    //TODO: Maybe move adjusters to UITest.hx
    public function new() 
    {
        super();
        percentWidth = 100;
        percentHeight = 100;

        container = new Box();
        container.width = GameLayout.MAX_SIDEBARS_WIDTH;
        container.percentHeight = 90;

        var widthLabel:Label = new Label();
        var widthSlider:HorizontalSlider = new HorizontalSlider();
        var adjusterBox:HBox = new HBox();

        widthLabel.text = "" + container.width;
        widthSlider.min = GameLayout.MIN_SIDEBARS_WIDTH;
        widthSlider.max = GameLayout.MAX_SIDEBARS_WIDTH;
        widthSlider.pos = container.width;
        widthSlider.onChange = e -> {
            widthLabel.text = "" + widthSlider.value;
            container.width = widthSlider.value;
        };

        adjusterBox.addComponent(widthSlider);
        adjusterBox.addComponent(widthLabel);

        gameinfobox = new GameInfoBox(new TimeControl(600, 0), "Al", "ra");
        gameinfobox.horizontalAlign = 'center';
        gameinfobox.verticalAlign = 'center';

        container.addComponent(gameinfobox);
        addComponent(adjusterBox);
        addComponent(container);
    }
}