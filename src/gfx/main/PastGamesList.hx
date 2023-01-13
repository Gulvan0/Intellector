package gfx.main;

import gfx.profile.complex_components.GamesList;
import serialization.GameLogParser;
import net.shared.dataobj.GameInfo;
import haxe.ui.containers.VBox;
import dict.*;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/main_menu/past_games_list.xml"))
class PastGamesList extends VBox
{
    public var ownerLogin:Null<String>;
    private var list:GamesList;

    private function onGameClicked(info:GameInfo)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(info.log);
        SceneManager.toScreen(LiveGame(info.id, Past(parsedData, ownerLogin)));
    }

    public function insertAtBeginning(info:GameInfo)
    {
        list.insertAtBeginning(info);
    }

    public function appendGames(data:Array<GameInfo>)
    {
        list.appendGames(data);
    }

    public function new()
    {
        super();

        list = new GamesList(ownerLogin, [], onGameClicked);
        list.percentWidth = 100;
        addComponent(list);
    }
}