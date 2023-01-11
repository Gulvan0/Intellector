package gfx.main;

import serialization.GameLogParser;
import net.shared.dataobj.GameInfo;
import haxe.ui.containers.VBox;
import dict.*;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/past_games_list.xml"))
class PastGamesList extends VBox
{
    public var ownerLogin:Null<String>;

    private function onGameClicked(info:GameInfo)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(info.log);
        SceneManager.toScreen(LiveGame(info.id, Past(parsedData, ownerLogin)));
    }

    public function insertAtBeginning(info:GameInfo)
    {
        list.dataSource.insert(0, {info: info, watchedLogin: ownerLogin, onClicked: onGameClicked.bind(info)});
    }

    public function appendGames(data:Array<GameInfo>)
    {
        for (gameData in data)
            list.dataSource.add({info: gameData, watchedLogin: ownerLogin, onClicked: onGameClicked.bind(gameData)});
    }
}