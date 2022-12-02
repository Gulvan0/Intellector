package gfx.profile.complex_components;

import net.shared.dataobj.GameInfo;
import gfx.profile.simple_components.TimeControlFilterDropdown;
import gfx.common.GameWidget;
import haxe.ui.containers.ListView;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/games_list.xml"))
class GamesList extends ListView
{
    private var loadedGames:Map<Int, GameInfo> = [];
    private var profileOwnerLogin:String;
    private var onGameSelected:(info:GameInfo)->Void;

    public var loadedGamesCount(get, never):Int;

    private function get_loadedGamesCount():Int
    {
        return Lambda.count(loadedGames);
    }

    private function onGameClicked(id:Int)
    {
        onGameSelected(loadedGames.get(id));
    }

    public function appendGames(games:Array<GameInfo>)
    {
        for (info in games)
        {
            var gameWidgetData:GameWidgetData = {
                info: info,
                onClicked: onGameClicked.bind(info.id),
                watchedLogin: profileOwnerLogin
            };

            dataSource.add(gameWidgetData);
            loadedGames.set(info.id, info);
        }
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameInfo>, onGameSelected:(info:GameInfo)->Void)
    {
        super();
        this.profileOwnerLogin = profileOwnerLogin;
        this.onGameSelected = onGameSelected;

        addComponent(new GameWidget());

        appendGames(preloadedGames);
    }
}