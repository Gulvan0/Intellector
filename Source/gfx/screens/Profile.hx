package gfx.screens;

import net.shared.EloValue;
import gfx.profile.simple_components.FriendListEntry;
import gfx.profile.simple_components.PlayerLabel;
import haxe.ui.events.UIEvent;
import utils.AssetManager;
import haxe.ui.components.Button;
import haxe.Timer;
import utils.StringUtils;
import js.Browser;
import net.shared.TimeControlType;
import net.Requests;
import utils.MathUtils;
import dict.Utils;
import gfx.profile.data.FriendData;
import net.shared.StudyInfo;
import net.shared.GameInfo;
import gfx.profile.data.ProfileData;
import struct.ChallengeParams;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import utils.StringUtils;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/profile.xml"))
class Profile extends Screen
{
    private var profileOwnerLogin:String;
    private var isPlayer:Bool;
    private var data:ProfileData;

    @:bind(tcFiltersDropdown, UIEvent.CHANGE)
    private function onTimeControlDropdownChanged(e:UIEvent)
    {
        if (tcFiltersDropdown.selectedIndex == 0)
            setPastGameFilter(null);
        else
            setPastGameFilter(TimeControlType.createByIndex(tcFiltersDropdown.selectedIndex - 1));
    }

    private function fillTimeControlFiltersDropdown(totalPastGames:Int, elo:Map<TimeControlType, EloValue>, gamesCntByTimeControl:Map<TimeControlType, Int>)
    {
        var allGamesEntry:Dynamic = {};
        allGamesEntry.tc = "All Games"; //TODO: Change to dict phrase
        allGamesEntry.games = 'Games: $totalPastGames'; //TODO: Change to dict phrase
        allGamesEntry.elo = "";
        allGamesEntry.icon = "assets/symbols/profile/any_time_control.svg"; //TODO: Move path to AssetManager
        tcFiltersDropdown.dataSource.add(allGamesEntry);

        for (timeControl in TimeControlType.createAll())
        {
            var tcGameCnt:Int = gamesCntByTimeControl.get(timeControl);
            var tcElo:EloValue = elo.get(timeControl);
            var tcEloStr:String = eloToStr(tcElo);

            var entry:Dynamic = {};
            entry.tc = timeControl == Correspondence? Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME) : timeControl.getName();
            entry.games = 'Games: $tcGameCnt'; //TODO: Change to dict phrase
            entry.elo = 'ELO: $tcEloStr'; //TODO: Change to dict phrase
            entry.icon = AssetManager.timeControlPath(timeControl);
            tcFiltersDropdown.dataSource.add(entry);
        }
    }

    public function new(ownerLogin:String, data:ProfileData)
    {
        super();

        this.profileOwnerLogin = ownerLogin;
        this.isPlayer = LoginManager.isPlayer(ownerLogin);
        this.data = data;

        this.gamesLoaded = data.preloadedGames.length;
        this.studiesLoaded = data.preloadedStudies.length;

        this.activeStudyFilters = [];
        this.activePastGameTimeControlFilter = null;

        userLabelBox.addComponent(new PlayerLabel(ownerLogin, data.elo));
        rolesLabel.text = data.roles.map(role -> Dictionary.getPhrase(PROFILE_ROLE_TEXT(role))).join(', ');

        switch data.status 
        {
            case Offline(secondsSinceLastAction):
                statusLabel.text = Dictionary.getPhrase(PROFILE_STATUS_LAST_SEEN, [Utils.getTimePassedString(secondsSinceLastAction)]);
                sendChallengeBtn.hidden = true;
                followBtn.hidden = true;
            case Online:
                statusLabel.text = Dictionary.getPhrase(PROFILE_STATUS_ONLINE);
                sendChallengeBtn.hidden = false;
                followBtn.hidden = true;
            case InGame:
                statusLabel.text = Dictionary.getPhrase(PROFILE_STATUS_INGAME);
                sendChallengeBtn.hidden = true;
                followBtn.hidden = false;
        }

        addFriendBtn.hidden = data.isFriend;
        removeFriendBtn.hidden = !data.isFriend;

        //fillFriendList(data.friends);
        fillTimeControlFiltersDropdown(data.totalPastGames, data.elo, data.gamesCntByTimeControl);
        appendGames(data.preloadedGames);
        appendStudies(data.preloadedStudies);
        refreshOngoing(data.gamesInProgress);
    }
}