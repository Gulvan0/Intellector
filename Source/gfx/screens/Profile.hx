package gfx.screens;

import haxe.Timer;
import utils.StringUtils;
import js.Browser;
import net.shared.TimeControlType;
import net.Requests;
import utils.MathUtils;
import dict.Utils;
import gfx.profile.FriendData;
import gfx.profile.SimpleComponents;
import net.shared.OverviewStudyData;
import net.shared.OverviewGameData;
import gfx.profile.ProfileData;
import struct.ChallengeParams;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/profile.xml"))
class Profile extends Screen
{
    private static inline final maxEntriesPerRequest:Int = 10;

    private var profileOwnerLogin:String;
    private var isPlayer:Bool;

    private var gamesLoaded:Int;
    private var studiesLoaded:Int;

    private var activePastGameTimeControlFilter:Null<TimeControlType>;
    private var activeStudyFilters:Array<String>;

    @:bind(sendChallengeBtn, MouseEvent.CLICK)
    private function sendChallenge(e)
    {
        var params:ChallengeParams = ChallengeParams.loadFromCookies();
        params.type = Direct(profileOwnerLogin);
        Dialogs.specifyChallengeParams(params);
    }

    @:bind(followBtn, MouseEvent.CLICK)
    private function follow(e)
    {
        Networker.emitEvent(FollowPlayer(profileOwnerLogin));
    }

    @:bind(addFriendBtn, MouseEvent.CLICK)
    private function addFriend(e)
    {
        addFriendBtn.hidden = true;
        Networker.emitEvent(AddFriend(profileOwnerLogin));
        Timer.delay(() -> {
            removeFriendBtn.hidden = false;
        }, 3000);
    }

    @:bind(removeFriendBtn, MouseEvent.CLICK)
    private function removeFriend(e)
    {
        removeFriendBtn.hidden = true;
        Networker.emitEvent(RemoveFriend(profileOwnerLogin));
        Timer.delay(() -> {
            addFriendBtn.hidden = false;
        }, 3000);
    }

    private function fillFriendList(friends:Array<FriendData>)
    {
        for (data in friends)
            friendsSV.addComponent(SimpleComponents.friendEntry(data));
    }

    private function appendGames(games:Array<OverviewGameData>)
    {
        for (data in games)
            gamesList.dataSource.add(data);

        gamesLoaded += games.length;
    }

    private function appendStudies(studies:Array<OverviewStudyData>)
    {
        for (data in studies)
            studiesList.dataSource.add(data);

        studiesLoaded += studies.length;
    }

    private function refreshOngoing(games:Array<OverviewGameData>)
    {
        ongoingList.dataSource.clear();
        for (data in games)
            ongoingList.dataSource.add(data);
    }

    private function updateLoadMoreBtn(button:Button, hasMore:Bool)
    {
        button.disabled = !hasMore;
    }

    private function addStudyFilter(tag:String)
    {
        if (Lambda.has(activeStudyFilters, tag))
            return;
        
        studiesList.dataSource.clear();
        studiesLoaded = 0;

        //TODO: Update visual representation

        activeStudyFilters.push(tag);
        Requests.getPlayerStudies(profileOwnerLogin, studiesLoaded, maxEntriesPerRequest, activeStudyFilters, appendStudies, updateLoadMoreBtn.bind(gamesLoadMoreBtn));
    }

    private function removeStudyFilter(tag:String)
    {
        if (!Lambda.has(activeStudyFilters, tag))
            return;

        studiesList.dataSource.clear();
        studiesLoaded = 0;

        //TODO: Update visual representation

        activeStudyFilters.remove(tag);
        Requests.getPlayerStudies(profileOwnerLogin, studiesLoaded, maxEntriesPerRequest, activeStudyFilters, appendStudies, updateLoadMoreBtn.bind(studiesLoadMoreBtn));
    }

    
    private function clearStudyFilters()
    {
        if (Lambda.empty(activeStudyFilters))
            return;

        studiesList.dataSource.clear();
        studiesLoaded = 0;

        //TODO: Update visual representation

        activeStudyFilters = [];
        Requests.getPlayerStudies(profileOwnerLogin, studiesLoaded, maxEntriesPerRequest, activeStudyFilters, appendStudies, updateLoadMoreBtn.bind(studiesLoadMoreBtn));
    }

    private function setPastGameFilter(timeControl:Null<TimeControlType>)
    {
        if (activePastGameTimeControlFilter == timeControl)
            return;

        gamesList.dataSource.clear();
        gamesLoaded = 0;

        //TODO: Update visual representation

        activePastGameTimeControlFilter = timeControl;
        Requests.getPlayerPastGames(profileOwnerLogin, gamesLoaded, maxEntriesPerRequest, activePastGameTimeControlFilter, appendGames, updateLoadMoreBtn.bind(gamesLoadMoreBtn));
    }

    //TODO: Bind
    private function onPastGamesTabSwitched(e)
    {
        var timeControl:Null<TimeControlType>; //TODO: Define
        setPastGameFilter(timeControl);
    }

    //TODO: Bind
    private function onAddStudyTagFilterPressed(e)
    {
        Dialogs.prompt(PROFILE_TAG_FILTER_PROMPT_QUESTION_TEXT, All, tag -> {
            var normalizedTag:String = StringUtils.shorten(tag, MaxChars.StudyTag, false);
            addStudyFilter(normalizedTag);
        });
    }

    //TODO: Bind
    private function onClearStudyTagFiltersPressed(e)
    {
        clearStudyFilters();
    }

    @:bind(gamesLoadMoreBtn, MouseEvent.CLICK)
    private function onMoreGamesRequested(e)
    {
        Requests.getPlayerPastGames(profileOwnerLogin, gamesLoaded, maxEntriesPerRequest, activePastGameTimeControlFilter, appendGames, updateLoadMoreBtn.bind(gamesLoadMoreBtn));
    }

    @:bind(studiesLoadMoreBtn, MouseEvent.CLICK)
    private function onMoreStudiesRequested(e)
    {
        Requests.getPlayerStudies(profileOwnerLogin, studiesLoaded, maxEntriesPerRequest, activeStudyFilters, appendStudies, updateLoadMoreBtn.bind(studiesLoadMoreBtn));
    }

    @:bind(ongoingReloadBtn, MouseEvent.CLICK)
    private function onOngoingReloadRequested(e)
    {
        Requests.getPlayerOngoingGames(profileOwnerLogin, refreshOngoing);
    }

    public function new(ownerLogin:String, data:ProfileData)
    {
        super();

        this.profileOwnerLogin = ownerLogin;
        this.isPlayer = LoginManager.isPlayer(ownerLogin);

        this.gamesLoaded = data.preloadedGames.length;
        this.studiesLoaded = data.preloadedStudies.length;

        this.activeStudyFilters = [];
        this.activePastGameTimeControlFilter = null;

        userLabelBox.addComponent(SimpleComponents.playerLabel(ownerLogin, data.getMainELO()));
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

        fillFriendList(data.friends);
        appendGames(data.preloadedGames);
        appendStudies(data.preloadedStudies);
        refreshOngoing(data.gamesInProgress);
    }
}