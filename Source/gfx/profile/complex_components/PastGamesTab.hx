package gfx.profile.complex_components;

import dict.Dictionary;
import net.shared.EloValue;
import net.shared.GameInfo;
import serialization.GameLogParser;
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

    private function onGameClicked(info:GameInfo)
    {
        var parsedData:GameLogParserOutput = GameLogParser.parse(info.log);
        SceneManager.toScreen(LiveGame(info.id, Past(parsedData, profileOwnerLogin)));
    }

    private function onTimeControlFilterChanged(newValue:Null<TimeControlType>)
    {
        list.dataSource.clear();
        activeTimeControlFilter = newValue;
        Requests.getPlayerPastGames(profileOwnerLogin, 0, GAMES_PAGE_SIZE, activeTimeControlFilter, onGamesLoaded);
    }

    private function onGamesLoaded(games:Array<GameInfo>, hasNext:Bool)
    {
        list.appendGames(games);
        this.hasNext = hasNext;
    }

    private function onScrolled()
    {
        if (hasNext && list.vscrollPos >= list.vscrollMax) 
            Requests.getPlayerPastGames(profileOwnerLogin, list.loadedGamesCount, GAMES_PAGE_SIZE, activeTimeControlFilter, onGamesLoaded);
    }

    public function new(profileOwnerLogin:String, preloadedGames:Array<GameInfo>, elo:Map<TimeControlType, EloValue>, gamesCntByTimeControl:Map<TimeControlType, Int>, totalPastGames:Int)
    {
        super();
        this.text = Dictionary.getPhrase(PROFILE_GAMES_TAB_TITLE);
        this.profileOwnerLogin = profileOwnerLogin;
        this.activeTimeControlFilter = null;
        this.hasNext = preloadedGames.length < totalPastGames;

        tcFilterDropdown = new TimeControlFilterDropdown(elo, gamesCntByTimeControl, totalPastGames, onTimeControlFilterChanged);
        tcFilterDropdown.horizontalAlign = 'center';
        addComponent(tcFilterDropdown);

        list = new GamesList(profileOwnerLogin, preloadedGames, onGameClicked);
        addComponent(list);

        list.onScroll = _ -> {onScrolled();};
    }
}