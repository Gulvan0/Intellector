package gfx.main;

import haxe.ui.containers.VBox;
import dict.*;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/main_menu/past_games_list.xml"))
class PastGamesList extends VBox
{
    public var ownerLogin:Null<String>;

    public function appendGames(data:Array<{id:Int, log:String}>)
    {
        for (gameData in data)
            list.dataSource.add({id:gameData.id, log:gameData.log, watchedLogin:ownerLogin});
    }
}