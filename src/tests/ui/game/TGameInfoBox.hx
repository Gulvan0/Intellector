package tests.ui.game;

import net.shared.Outcome.DrawishOutcomeType;
import net.shared.Outcome.DecisiveOutcomeType;
import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import net.shared.PieceColor;
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
import net.shared.board.Situation;

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

    private function _act_rollback() 
    {
        gameinfobox.handleNetEvent(Rollback(1, null));
        playthrough_sit = previousSituations.pop();
    }

    @iterations(14)
    private function _seq_seeResolutions(i:Int) 
    {
        if (i == 0)
            update();

        var decisiveOutcomes:Array<DecisiveOutcomeType> = DecisiveOutcomeType.createAll();
        var drawishOutcomes:Array<DrawishOutcomeType> = DrawishOutcomeType.createAll();

        if (i < decisiveOutcomes.length * 2)
        {
            var winner:PieceColor = i % 2 == 0? White : Black;
            var outcome = decisiveOutcomes[Math.floor(i/2)];
            gameinfobox.handleNetEvent(GameEnded(Decisive(outcome, winner), true, null, null));
        }
        else
            gameinfobox.handleNetEvent(GameEnded(Drawish(drawishOutcomes[i - decisiveOutcomes.length * 2]), true, null, null));
    }

    private override function getComponent():ComponentGraphics
    {
		return AdjustableContent(gameinfobox, LiveGame.MIN_SIDEBARS_WIDTH, LiveGame.MAX_SIDEBARS_WIDTH, -1, -1);
    }

    private override function rebuildComponent()
    {
        previousSituations = [];
        playthrough_sit = Situation.defaultStarting();

        if (!_initparam_actualization)
        {
            gameinfobox = new GameInfoBox();
            gameinfobox.init(New(_initparam_whiteLogin, _initparam_blackLogin, null, _initparam_timeControl, null, Date.now()));
            return;
        }
        
        var po:GameLogParserOutput = new GameLogParserOutput();
        po.whiteRef = _initparam_whiteLogin;
        po.blackRef = _initparam_blackLogin;
        po.datetime = Date.now();
        po.timeControl = _initparam_timeControl;
        po.movesPlayed = [RawPly.construct(new HexCoords(1, 5), new HexCoords(1, 3)), RawPly.construct(new HexCoords(1, 0), new HexCoords(1, 2))];
        po.outcome = Decisive(Resign, Black);

        gameinfobox = new GameInfoBox();
        gameinfobox.init(Past(po, null));

        for (ply in po.movesPlayed)
        {
            previousSituations.push(playthrough_sit.copy());
            playthrough_sit.performRawPly(ply);
        }
    }
}