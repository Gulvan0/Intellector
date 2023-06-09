package gfx.profile.complex_components;

import gfx.scene.SceneManager;
import net.shared.dataobj.GameModelData;
import haxe.ui.events.UIEvent;
import js.Browser;
import haxe.Timer;
import dict.Dictionary;
import net.shared.EloValue;
import net.shared.TimeControlType;
import net.Requests;
import haxe.ui.containers.VBox;
import gfx.profile.simple_components.TimeControlFilterDropdown;

class PastGamesTab extends VBox
{
    private static inline final GAMES_PAGE_SIZE:Int = 10;

    private var tcFilterDropdown:TimeControlFilterDropdown;
    private var list:GamesList;

    private var profileOwnerLogin:String;
    private var activeTimeControlFilter:Null<TimeControlType>;
    private var hasNext:Bool;
    private var canLoad:Bool = true;

    private function onGameClicked(data:GameModelData)
    {
        SceneManager.getScene().toScreen(GameFromModelData(data, profileOwnerLogin));
    }

    private function onTimeControlFilterChanged(newValue:Null<TimeControlType>)
    {
        list.clear();
        activeTimeControlFilter = newValue;
        Requests.getPlayerPastGames(profileOwnerLogin, 0, GAMES_PAGE_SIZE, activeTimeControlFilter, onGamesLoaded);
    }

    private function onGamesLoaded(games:Array<GameModelData>, hasNext:Bool)
    {
        list.appendGames(games);
        this.hasNext = hasNext;
        Timer.delay(() -> {canLoad = true;}, 100);
    }

    private function onScrolled(e)
    {
        if (hasNext && canLoad) 
        {
            var loadedCnt:Int = list.loadedGamesCount;
            if (Browser.window.scrollY * loadedCnt >= (Browser.document.body.scrollHeight - Browser.window.innerHeight) * (loadedCnt - 1))
            {
                canLoad = false;
                Requests.getPlayerPastGames(profileOwnerLogin, loadedCnt, GAMES_PAGE_SIZE, activeTimeControlFilter, onGamesLoaded);
            }
        }
    }

    @:bind(this, UIEvent.SHOWN)
    private function onShown(e) 
    {
        Browser.document.addEventListener('scroll', onScrolled);
    }

    @:bind(this, UIEvent.HIDDEN)
    private function onHidden(e) 
    {
        Browser.document.removeEventListener('scroll', onScrolled);
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameModelData>, elo:Map<TimeControlType, EloValue>, gamesCntByTimeControl:Map<TimeControlType, Int>, totalPastGames:Int)
    {
        super();
        this.percentWidth = 100;
        this.text = Dictionary.getPhrase(PROFILE_GAMES_TAB_TITLE);
        this.profileOwnerLogin = profileOwnerLogin;
        this.activeTimeControlFilter = null;
        this.hasNext = preloadedGames.length < totalPastGames;

        tcFilterDropdown = new TimeControlFilterDropdown(elo, gamesCntByTimeControl, totalPastGames, onTimeControlFilterChanged);
        tcFilterDropdown.horizontalAlign = 'center';
        addComponent(tcFilterDropdown);

        list = new GamesList(profileOwnerLogin, preloadedGames, onGameClicked);
        list.percentWidth = 100;
        addComponent(list);
    }
}