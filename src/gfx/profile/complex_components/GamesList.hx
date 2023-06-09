package gfx.profile.complex_components;

import net.shared.dataobj.GameModelData;
import haxe.ui.events.UIEvent;
import haxe.Timer;
import haxe.ui.containers.VBox;
import gfx.profile.simple_components.TimeControlFilterDropdown;
import gfx.common.GameWidget;
import haxe.ui.containers.ListView;

class GamesList extends VBox
{
    private var loadedGames:Map<Int, GameModelData> = [];
    private var profileOwnerLogin:String;
    private var onGameSelected:(info:GameModelData)->Void;

    private var queuedGames:Array<GameModelData> = [];
    private var loadingTimer:Null<Timer> = null;

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
        if (loadingTimer != null)
            loadingTimer.stop();
        loadingTimer = null;

        removeAllComponents();
        queuedGames = [];
        loadedGames = [];
    }

    public function insertAtBeginning(data:GameModelData)
    {
        var gameWidgetData:GameWidgetData = {
            data: data,
            onClicked: onGameClicked.bind(data.gameID),
            watchedLogin: profileOwnerLogin
        };

        addComponentAt(new GameWidget(gameWidgetData), 0);
        loadedGames.set(data.gameID, data);
    }

    public function appendGames(games:Array<GameModelData>)
    {
        queuedGames = queuedGames.concat(games);

        if (loadingTimer == null)
            appendQueuedGame();
    }

    private function appendQueuedGame()
    {
        if (Lambda.empty(queuedGames))
        {
            loadingTimer = null;
            return;
        }

        var data = queuedGames.shift();

        var gameWidgetData:GameWidgetData = {
            data: data,
            onClicked: onGameClicked.bind(data.gameID),
            watchedLogin: profileOwnerLogin
        };

        addComponent(new GameWidget(gameWidgetData));
        loadedGames.set(data.gameID, data);

        loadingTimer = Timer.delay(appendQueuedGame, 30);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onHidden(e) 
    {
        if (loadingTimer != null)
            loadingTimer.stop();
        loadingTimer = null;
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameModelData>, onGameSelected:(info:GameModelData)->Void)
    {
        super();
        this.profileOwnerLogin = profileOwnerLogin;
        this.onGameSelected = onGameSelected;

        appendGames(preloadedGames);
    }
}