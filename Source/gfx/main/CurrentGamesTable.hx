package gfx.main;

import dict.Utils;
import net.shared.GameInfo;
import utils.StringUtils.eloToStr;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import dict.Dictionary;
import haxe.Timer;
import serialization.GameLogParser;
import net.Requests;
import net.shared.PieceColor;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/current_games_table.xml"))
class CurrentGamesTable extends VBox
{
    private var gameIDs:Array<Int> = [];

    public function appendGames(data:Array<GameInfo>)
    {
        for (gameData in data)
        {
            var parsedData:GameLogParserOutput = GameLogParser.parse(gameData.log);

            var whiteLabel:String = Utils.playerRef(parsedData.whiteRef);
            var blackLabel:String = Utils.playerRef(parsedData.blackRef);
            if (parsedData.elo != null)
            {
                whiteLabel += ' (${eloToStr(parsedData.elo[White])})';
                whiteLabel += ' (${eloToStr(parsedData.elo[Black])})';
            }

            table.dataSource.add({timeControl: parsedData.timeControl, players: '$whiteLabel vs $blackLabel', bracket: Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(false))});
            gameIDs.push(gameData.id);
        }
    }

    public function removeGame(id:Int)
    {
        var index:Null<Int> = gameIDs.indexOf(id);

        if (index == null)
            return;

        gameIDs.splice(index, 1);
        table.dataSource.removeAt(index);
    }

    @:bind(table, UIEvent.CHANGE)
    private function onGameSelected(e:UIEvent)
    {
        Requests.getGame(gameIDs[table.selectedIndex]);
    }

    @:bind(reloadBtn, MouseEvent.CLICK)
    private function reload(?e)
    {
        reloadBtn.disabled = true;
        table.dataSource.clear();
        gameIDs = [];
        loadCurrentGames();
        Timer.delay(() -> {
            if (reloadBtn != null)
                reloadBtn.disabled = false;
        }, 5000);
    }

    private function loadCurrentGames()
    {
        Requests.getCurrentGames(appendGames);
    }

    public function new()
    {
        super();
        table.selectionMode = DISABLED;
    }
}