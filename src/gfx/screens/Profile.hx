package gfx.screens;

import gfx.scene.SceneManager;
import gfx.scene.Screen;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import haxe.ui.core.Component;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;
import gfx.basic_components.utils.DimValue.assignWidth;
import haxe.ui.events.UIEvent;
import gfx.profile.complex_components.OngoingGamesTab;
import gfx.profile.complex_components.StudiesTab;
import gfx.profile.complex_components.PastGamesTab;
import gfx.profile.complex_components.FriendList;
import gfx.profile.complex_components.ProfileHeader;
import net.shared.dataobj.ProfileData;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/profile/profile.xml"))
class Profile extends Screen
{
    private var profileOwnerLogin:String;
    private var isPlayer:Bool;
    private var data:ProfileData;

    private function onEnter()
    {
        SceneManager.addResizeHandler(onResize);
    }

    private function onClose()
    {
        SceneManager.removeResizeHandler(onResize);
    }

    public function getTitle():Null<Phrase>
    {
        return PLAYER_PROFILE_SCREEN_TITLE(profileOwnerLogin);
    }

    public function getURLPath():Null<String>
    {
        return 'player/$profileOwnerLogin';
    }

    public function getPage():ViewedScreen
    {
        return Profile(profileOwnerLogin);
    }

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [];
    }

    private function onResize()
    {
        if (haxe.ui.core.Screen.instance.actualWidth > 800)
            assignWidth(contentsBox, Exact(800));
        else
            assignWidth(contentsBox, Percent(100));
    }

    public function new(ownerLogin:String, data:ProfileData)
    {
        super();

        this.profileOwnerLogin = ownerLogin;
        this.isPlayer = LoginManager.isPlayer(ownerLogin);
        this.data = data;

        var header:ProfileHeader = new ProfileHeader(ownerLogin, data);
        var friendsList:FriendList = new FriendList(Percent(100), 50);

        friendsList.fill(data.friends);

        var pastGamesTab:PastGamesTab = new PastGamesTab(ownerLogin, data.preloadedGames, data.elo, data.gamesCntByTimeControl, data.totalPastGames);
        var studiesTab:StudiesTab = new StudiesTab(ownerLogin, data.preloadedStudies, data.totalStudies);
        var ongoingGamesTab:OngoingGamesTab = new OngoingGamesTab(ownerLogin, data.gamesInProgress);

        contentsBox.addComponentAt(header, 0);
        contentsBox.addComponentAt(friendsList, 1);

        tabView.addComponent(pastGamesTab);
        tabView.addComponent(studiesTab);
        tabView.addComponent(ongoingGamesTab);

        assignWidth(header, Percent(100));
    }
}