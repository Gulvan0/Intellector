package gfx.profile.complex_components;

import haxe.ui.containers.VBox;
import net.shared.dataobj.GameInfo;
import gfx.profile.simple_components.TimeControlFilterDropdown;
import gfx.common.GameWidget;
import haxe.ui.containers.ListView;

class GamesList extends VBox
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

    public function clear()
    {
        removeAllComponents();
        loadedGames = [];
    }

    public function insertAtBeginning(info:GameInfo)
    {
        var gameWidgetData:GameWidgetData = {
            info: info,
            onClicked: onGameClicked.bind(info.id),
            watchedLogin: profileOwnerLogin
        };

        addComponentAt(new GameWidget(gameWidgetData), 0);
        loadedGames.set(info.id, info);
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

            addComponent(new GameWidget(gameWidgetData));
            loadedGames.set(info.id, info);
        }
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameInfo>, onGameSelected:(info:GameInfo)->Void)
    {
        super();
        this.profileOwnerLogin = profileOwnerLogin;
        this.onGameSelected = onGameSelected;

        appendGames(preloadedGames);
    }
}