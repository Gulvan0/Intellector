package gfx.profile.complex_components;

import haxe.ui.events.UIEvent;
import haxe.Timer;
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

    private var queuedGames:Array<GameInfo> = [];
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

        var info = queuedGames.shift();

        var gameWidgetData:GameWidgetData = {
            info: info,
            onClicked: onGameClicked.bind(info.id),
            watchedLogin: profileOwnerLogin
        };

        addComponent(new GameWidget(gameWidgetData));
        loadedGames.set(info.id, info);

        loadingTimer = Timer.delay(appendQueuedGame, 30);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onHidden(e) 
    {
        if (loadingTimer != null)
            loadingTimer.stop();
        loadingTimer = null;
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameInfo>, onGameSelected:(info:GameInfo)->Void)
    {
        super();
        this.profileOwnerLogin = profileOwnerLogin;
        this.onGameSelected = onGameSelected;

        appendGames(preloadedGames);
    }
}