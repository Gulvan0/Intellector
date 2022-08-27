package gfx.main;

import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import dict.Dictionary;
import haxe.Timer;
import serialization.GameLogParser;
import net.Requests;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/current_games_table.xml"))
class CurrentGamesTable extends VBox
{
    private var gameIDs:Array<Int> = [];

    public function appendGames(data:Array<{id:Int, currentLog:String}>)
    {
        for (gameData in data)
        {
            var parsedData:GameLogParserOutput = GameLogParser.parse(gameData.currentLog);
            table.dataSource.add({time: parsedData.timeControl, players: '${parsedData.whiteLogin} vs ${parsedData.blackLogin}', bracket: Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(false))});
            gameIDs.push(gameData.id);
        }
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

    public function loadCurrentGames()
    {
        Requests.getCurrentGames(appendGames);
    }
}