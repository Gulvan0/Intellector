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

    //TODO: Fill

    public function new(ownerLogin:String, data:ProfileData)
    {
        super();

        this.profileOwnerLogin = ownerLogin;
        this.isPlayer = LoginManager.isPlayer(ownerLogin);
        this.data = data;
    }
}