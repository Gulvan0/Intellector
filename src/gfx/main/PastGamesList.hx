package gfx.main;

import gfx.scene.SceneManager;
import net.shared.dataobj.GameModelData;
import gfx.profile.complex_components.GamesList;
import haxe.ui.containers.VBox;
import dict.*;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/main/past_games_list.xml"))
class PastGamesList extends VBox
{
    public var ownerLogin:Null<String>;
    private var list:GamesList;

    private function onGameClicked(data:GameModelData)
    {
        SceneManager.getScene().toScreen(GameFromModelData(data, ownerLogin));
    }

    public function insertAtBeginning(data:GameModelData)
    {
        list.insertAtBeginning(data);
    }

    public function appendGames(data:Array<GameModelData>)
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