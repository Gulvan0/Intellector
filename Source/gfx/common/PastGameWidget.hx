package gfx.common;

import net.shared.EloValue;
import gameboard.Board;
import gfx.basic_components.BoardWrapper;
import struct.PieceColor;
import dict.Dictionary;
import openings.OpeningTree;
import dict.Utils;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import haxe.ui.core.ItemRenderer;

typedef PastGameWidgetData = {
    var id:Int;
    var log:String;
    var watchedLogin:Null<String>;
} 

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/past_game_widget.xml"))
class PastGameWidget extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        if (data != null) 
        {
            var widgetData:PastGameWidgetData = data;
            var parsedData:GameLogParserOutput = GameLogParser.parse(widgetData.log);

            var orientationColor:PieceColor = data.watchedLogin == null? White : parsedData.getParticipantColor(widgetData.watchedLogin);
            var board = new Board(parsedData.currentSituation, orientationColor, 40, None);

            var boardWrapper:BoardWrapper = new BoardWrapper(board);
            boardWrapper.percentHeight = 100;
            boardWrapper.maxPercentWidth = 100;
        
            boardContainer.addComponent(boardWrapper);

            var whiteLabel:String = parsedData.whiteLogin;
            if (parsedData.whiteELO != null)
                whiteLabel += ' (${eloToStr(parsedData.whiteELO)})';

            var blackLabel:String = parsedData.blackLogin;
            if (parsedData.blackELO != null)
                blackLabel += ' (${eloToStr(parsedData.blackELO)})';

            datetimeLabel.text = DateTools.format(parsedData.datetime, "%d.%m.%Y %H:%M:%S");
            timeControlLabel.text = parsedData.timeControl.toString();
            opponentsLabel.text = '$whiteLabel vs $blackLabel';
            resultLabel.text = Utils.getResolution(parsedData.outcome);
            if (parsedData.startingSituation.isDefaultStarting())
                openingLabel.text = OpeningTree.getOpening(parsedData.movesPlayed);
            else
                openingLabel.text = Dictionary.getPhrase(CUSTOM_STARTING_POSITION);

            onClick = e -> {
                SceneManager.toScreen(LiveGame(widgetData.id, Past(parsedData, widgetData.watchedLogin)));
            };
        }
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        boardContainer.width = boardContainer.height / BoardWrapper.invAspectRatio(false);
        return b;
    }
}