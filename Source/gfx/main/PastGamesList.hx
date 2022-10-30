package gfx.main;

import serialization.GameLogParser;
import net.shared.GameInfo;
import haxe.ui.containers.VBox;
import dict.*;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/past_games_list.xml"))
class PastGamesList extends VBox
{
    public var ownerLogin:Null<String>;
    private var minID:Null<Int>;

    private function onGameClicked(info:GameInfo)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(info.log);
        SceneManager.toScreen(LiveGame(info.id, Past(parsedData, ownerLogin)));
    }

    public function appendGames(data:Array<GameInfo>)
    {
        for (gameData in data)
        {
            list.dataSource.add({info: gameData, watchedLogin: ownerLogin, onClicked: onGameClicked.bind(gameData)});
            if (minID == null || gameData.id < minID)
                minID = gameData.id;
        }
    }

    public function getMinID():Null<Int>
    {
        return minID;    
    }
}