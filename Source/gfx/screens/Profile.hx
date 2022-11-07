package gfx.screens;

import gfx.profile.complex_components.OngoingGamesTab;
import gfx.profile.complex_components.StudiesTab;
import gfx.profile.complex_components.PastGamesTab;
import gfx.profile.complex_components.FriendList;
import gfx.profile.complex_components.ProfileHeader;
import net.shared.ProfileData;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/profile.xml"))
class Profile extends Screen
{
    private var profileOwnerLogin:String;
    private var isPlayer:Bool;
    private var data:ProfileData;

    public function new(ownerLogin:String, data:ProfileData)
    {
        super();

        this.profileOwnerLogin = ownerLogin;
        this.isPlayer = LoginManager.isPlayer(ownerLogin);
        this.data = data;

        var header:ProfileHeader = new ProfileHeader(ownerLogin, data);
        var friendsList:FriendList = new FriendList(Percent(100), 50);

        var pastGamesTab:PastGamesTab = new PastGamesTab(ownerLogin, data.preloadedGames, data.elo, data.gamesCntByTimeControl, data.totalPastGames);
        var studiesTab:StudiesTab = new StudiesTab(data.preloadedStudies, data.totalStudies);
        var ongoingGamesTab:OngoingGamesTab = new OngoingGamesTab(ownerLogin, data.gamesInProgress);

        contentsBox.addComponentAt(header, 0);
        contentsBox.addComponentAt(friendsList, 1);

        tabView.addComponent(pastGamesTab);
        tabView.addComponent(studiesTab);
        tabView.addComponent(ongoingGamesTab);

        this.responsiveComponents = [
            contentsBox => [Width => Min([VW(100), Exact(800)])]
        ];
    }
}