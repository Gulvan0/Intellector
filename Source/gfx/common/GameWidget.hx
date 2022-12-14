package gfx.common;

import net.shared.dataobj.GameInfo;
import net.shared.board.Situation;
import gameboard.lightweight.LighttBoard.LightBoard;
import haxe.CallStack;
import utils.StringUtils.eloToStr;
import haxe.ui.containers.VBox;
import haxe.ui.styles.Style;
import haxe.ui.containers.HBox;
import haxe.ui.components.Label;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
import net.shared.EloValue;
import gameboard.Board;
import gfx.basic_components.BoardWrapper;
import net.shared.PieceColor;
import dict.Dictionary;
import openings.OpeningTree;
import dict.Utils;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import haxe.ui.core.ItemRenderer;

typedef GameWidgetData = 
{
    var info:GameInfo;
    var watchedLogin:Null<String>;
    var onClicked:Void->Void;
} 

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/game_widget.xml"))
class GameWidget extends ItemRenderer
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
        var orientationColor:PieceColor = watchedColor == null? shownSituation.turnColor : watchedColor;
        var board:LightBoard = new LightBoard(shownSituation, orientationColor, 10, true);
        board.x = (boardContainer.width - board.width) / 2;
        board.y = (boardContainer.height - board.height) / 2;
        boardContainer.addChild(board);
    }

    @:bind(fullBox, MouseEvent.CLICK)
    private function onClicked(e)
    {
        typedData.onClicked();
    }

    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);

        if (data == null || typedData != null)
            return;
        
        typedData = data;

        var parsedData:GameLogParserOutput = GameLogParser.parse(typedData.info.log);

        var watchedColor:Null<PieceColor> = null;
        if (typedData.watchedLogin != null)
            watchedColor = parsedData.getParticipantColor(typedData.watchedLogin);

        loadBoard(parsedData.currentSituation, watchedColor);

        var whitePlayerStr:String = Utils.playerRef(parsedData.whiteRef);
        var blackPlayerStr:String = Utils.playerRef(parsedData.blackRef);

        if (parsedData.elo != null)
        {
            whitePlayerStr += ' (${eloToStr(parsedData.elo[White])})';
            blackPlayerStr += ' (${eloToStr(parsedData.elo[Black])})';
        }

        opponentsLabelLongText = '$whitePlayerStr vs $blackPlayerStr';
        opponentsLabelTallText = '$whitePlayerStr\nvs\n$blackPlayerStr';

        if (parsedData.datetime != null)
            datetimeLabel.text = DateTools.format(parsedData.datetime, "%d.%m.%Y %H:%M:%S");
        else
            datetimeLabel.hidden = true;

        timeControlLabel.text = parsedData.timeControl.toString();
        opponentsLabel.text = opponentsLabelLongText;
        resultLabel.text = Utils.getResolution(parsedData.outcome);

        if (parsedData.startingSituation.isDefaultStarting())
            openingLabel.text = OpeningTree.getOpening(parsedData.movesPlayed);
        else
            openingLabel.text = Dictionary.getPhrase(CUSTOM_STARTING_POSITION);
    }
}