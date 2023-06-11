package gfx.main;

import net.shared.TimeControl;
import net.shared.dataobj.GameModelData;
import dict.Utils;
import utils.StringUtils.eloToStr;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import dict.Dictionary;
import haxe.Timer;
import net.Requests;
import net.shared.PieceColor;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/main/current_games_table.xml"))
class CurrentGamesTable extends VBox
{
    private var gameIDs:Array<Int> = [];

    public function appendGames(data:Array<GameModelData>)
    {
        for (gameData in data)
        {
            if (Lambda.has(gameIDs, gameData.gameID))
                continue;

            var whiteLabel:String = Utils.playerRef(gameData.playerRefs[White]);
            var blackLabel:String = Utils.playerRef(gameData.playerRefs[Black]);
            var rated:Bool = gameData.elo != null;
            if (rated)
            {
                whiteLabel += ' (${eloToStr(gameData.elo[White])})';
                blackLabel += ' (${eloToStr(gameData.elo[Black])})';
            }

            table.dataSource.add({timeControl: gameData.timeControl, players: '$whiteLabel vs $blackLabel', bracket: Dictionary.getPhrase(TABLEVIEW_BRACKET_RANKED(rated))});
            gameIDs.push(gameData.gameID);
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
        var gameID:Int = gameIDs[table.selectedIndex];
        table.selectedIndex = -1;
        Requests.getGame(gameID);
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
        table.selectionMode = ONE_ITEM;
    }
}