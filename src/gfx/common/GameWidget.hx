package gfx.common;

import net.shared.openings.OpeningDatabase;
import net.shared.Outcome;
import net.shared.TimeControl;
import net.shared.dataobj.GameModelData;
import gfx.game.board.Board;
import haxe.ui.containers.Box;
import net.shared.board.Situation;
import haxe.CallStack;
import utils.StringUtils.eloToStr;
import haxe.ui.containers.VBox;
import haxe.ui.styles.Style;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
import net.shared.EloValue;
import net.shared.PieceColor;
import dict.Dictionary;
import dict.Utils;

typedef GameWidgetData = 
{
    var data:GameModelData;
    var watchedLogin:Null<String>;
    var onClicked:Void->Void;
} 

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/game_widget.xml"))
class GameWidget extends Box
{
    private var typedData:GameWidgetData;

    private var opponentsLabelLongText:String;
    private var opponentsLabelTallText:String;

    private function setPadding(container:VBox, value:Float)
    {
        var style:Style = container.customStyle.clone();
        style.paddingLeft = value;
        style.paddingRight = value;
        style.paddingTop = value;
        style.paddingBottom = value;
        container.customStyle = style;
    }

    private function setFontSize(label:Label, value:Float)
    {
        var style:Style = label.customStyle.clone();
        style.fontSize = value;
        label.customStyle = style;
    }

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        var renderKeyWidth:Float = Math.min(800, this.width);

        setFontSize(opponentsLabel, renderKeyWidth * 0.02 + 6);
        setFontSize(openingLabel, renderKeyWidth * 0.016 + 5.2);
        setFontSize(resultLabel, renderKeyWidth * 0.016 + 5.2);
        setFontSize(datetimeLabel, renderKeyWidth * 0.0136 + 4.1);
        setFontSize(timeControlLabel, renderKeyWidth * 0.0136 + 4.1);
        setPadding(infoBox, renderKeyWidth / 40);
    }

    @:bind(opponentsLabelBox, UIEvent.RESIZE)
    private function onOpponentsBoxSizeChanged(e)
    {
        if (opponentsLabelBox.width / opponentsLabelBox.height < 10 / 3)
            opponentsLabel.text = opponentsLabelTallText;
        else
            opponentsLabel.text = opponentsLabelLongText;
    }

    private function loadBoard(shownSituation:Situation, watchedColor:Null<PieceColor>) 
    {
        var orientationColor:PieceColor = watchedColor ?? shownSituation.turnColor;
        var board:Board = new Board(shownSituation, orientationColor, None, 150, 150, true);
        board.horizontalAlign = "center";
        board.verticalAlign = "center";
        fullBox.addComponentAt(board, 0);
    }

    @:bind(fullBox, MouseEvent.CLICK)
    private function onClicked(e)
    {
        typedData.onClicked();
    }

    public function new(data:GameWidgetData) 
    {
        super();
        this.typedData = data;

        var watchedColor:Null<PieceColor> = null;
        if (typedData.watchedLogin != null)
            for (color in PieceColor.createAll())
                if (typedData.data.playerRefs[color].equals(typedData.watchedLogin))
                    watchedColor = color;

        var currentSituation:Situation = typedData.data.startingSituation;
        var outcome:Null<Outcome> = null;
        var hasAtLeastOneMove:Bool = false;
        for (item in typedData.data.eventLog)
            switch item.entry 
            {
                case Ply(ply):
                    currentSituation.performRawPly(ply);
                    hasAtLeastOneMove = true;
                case GameEnded(ot):
                    outcome = ot;
                    break;
                default:
            }
        loadBoard(currentSituation, watchedColor);

        var whitePlayerStr:String = Utils.playerRef(typedData.data.playerRefs[White]);
        var blackPlayerStr:String = Utils.playerRef(typedData.data.playerRefs[Black]);

        if (typedData.data.elo != null)
        {
            whitePlayerStr += ' (${eloToStr(typedData.data.elo[White])})';
            blackPlayerStr += ' (${eloToStr(typedData.data.elo[Black])})';
        }

        opponentsLabelLongText = '$whitePlayerStr vs $blackPlayerStr';
        opponentsLabelTallText = '$whitePlayerStr\nvs\n$blackPlayerStr';

        if (typedData.data.startTimestamp != null)
            datetimeLabel.text = typedData.data.startTimestamp.format(DotDelimitedDayWithSeparateTime);
        else
            datetimeLabel.hidden = true;

        timeControlLabel.text = typedData.data.timeControl.toString();
        opponentsLabel.text = opponentsLabelLongText;
        resultLabel.text = Utils.getResolution(outcome);

        if (typedData.data.startingSituation.isDefaultStarting())
            openingLabel.text = OpeningDatabase.get(currentSituation.serialize()).renderName(false);
        else if (hasAtLeastOneMove)
            openingLabel.text = Dictionary.getPhrase(OPENING_UNORTHODOX_LINE);
        else
            openingLabel.text = Dictionary.getPhrase(OPENING_UNORTHODOX_STARTING_POSITION);
    }
}