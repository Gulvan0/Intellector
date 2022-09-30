package gfx.profile.complex_components;

import haxe.Timer;
import haxe.ui.containers.VBox;
import net.Requests;
import struct.ChallengeParams;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import net.shared.ProfileData;
import gfx.profile.simple_components.PlayerLabel;
import haxe.ui.containers.Box;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/profile/profile_header.xml"))
class ProfileHeader extends VBox
{
    private var username:String;

    private var usernameLabel:PlayerLabel;

    @:bind(sendChallengeBtn, MouseEvent.CLICK)
    private function onSendChallengePressed(e)
    {
        Dialogs.specifyChallengeParams(ChallengeParams.directChallengeParams(username));
    }

    @:bind(followBtn, MouseEvent.CLICK)
    private function onFollowPressed(e)
    {
        Requests.followPlayer(username);
    }

    @:bind(addFriendBtn, MouseEvent.CLICK)
    private function onAddFriendPressed(e)
    {
        addFriendBtn.hidden = true;
        Networker.emitEvent(AddFriend(username));
        Timer.delay(() -> {
            removeFriendBtn.hidden = false;
        }, 3000);
    }

    @:bind(removeFriendBtn, MouseEvent.CLICK)
    private function onRemoveFriendPressed(e)
    {
        removeFriendBtn.hidden = true;
        Networker.emitEvent(RemoveFriend(username));
        Timer.delay(() -> {
            addFriendBtn.hidden = false;
        }, 3000);
    }

    public function new(username:String, profileData:ProfileData)
    {
        super();
        this.username = username;

        usernameLabel = new PlayerLabel(Exact(44), username, profileData.findMainELO(), false);
        upperHBox.addComponentAt(usernameLabel, 0);

        if (Lambda.empty(profileData.roles))
            rolesLabel.hidden = true;
        else
        {
            var rolesStr:Array<String> = [];
            for (role in profileData.roles)
                rolesStr.push(Dictionary.getPhrase(PROFILE_ROLE_TEXT(role)));
            rolesLabel.text = rolesStr.join(', ');
        }

        Utils.updateStatusLabel(statusLabel, profileData.status);

        switch profileData.status 
        {
            case Offline(secondsSinceLastAction):
                sendChallengeBtn.hidden = true;
                followBtn.hidden = true;
            case Online:
                sendChallengeBtn.hidden = LoginManager.isPlayer(username);
                followBtn.hidden = true;
            case InGame:
                sendChallengeBtn.hidden = true;
                followBtn.hidden = LoginManager.isPlayer(username);
        }

        if (profileData.isFriend)
            addFriendBtn.hidden = true;
        else
            removeFriendBtn.hidden = true;
    }
}