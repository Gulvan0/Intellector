package gfx.profile.complex_components;

import utils.StringUtils;
import struct.ChallengeParams;
import net.Requests;
import haxe.ui.events.MouseEvent;
import haxe.ui.components.Button;
import gfx.profile.simple_components.TCEloEntry;
import gfx.profile.data.EloData;
import net.shared.EloValue;
import utils.AssetManager;
import gfx.basic_components.AnnotatedImage;
import net.shared.TimeControlType;
import haxe.ds.BalancedTree;
import dict.Dictionary;
import gfx.profile.simple_components.PlayerLabel;
import gfx.profile.data.MiniProfileData;
import gfx.profile.Utils;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/mini_profile.xml"))
class MiniProfile extends Dialog
{
    private var username:String;

    private function resize()
    {
        width = Math.min(400, HaxeUIScreen.instance.actualWidth * 0.98);
    }

    public function onClose(?e)
    {
        SceneManager.removeResizeHandler(resize);
    }

    private function eloOrdinalNumber(gamesCnt:Int, tc:TimeControlType):Float
    {
        return -(gamesCnt + 0.1 * tc.getIndex());
    }

    @:bind(followBtn, MouseEvent.CLICK)
    private function onFollowPressed(e)
    {
        hideDialog(null);
        FollowManager.followPlayer(username);
    }

    @:bind(unfollowBtn, MouseEvent.CLICK)
    private function onUnfollowPressed(e)
    {
        hideDialog(null);
        FollowManager.stopFollowing();
    }

    @:bind(friendBtn, MouseEvent.CLICK)
    private function onFriendPressed(e)
    {
        hideDialog(null);
        Networker.emitEvent(AddFriend(username));
    }

    @:bind(unfriendBtn, MouseEvent.CLICK)
    private function onUnfriendPressed(e)
    {
        hideDialog(null);
        Networker.emitEvent(RemoveFriend(username));
    }

    @:bind(challengeBtn, MouseEvent.CLICK)
    private function onChallengePressed(e)
    {
        hideDialog(null);
        Dialogs.specifyChallengeParams(ChallengeParams.directChallengeParams(username));
    }

    @:bind(toProfileBtn, MouseEvent.CLICK)
    private function onToProfilePressed(e)
    {
        hideDialog(null);
        Requests.getPlayerProfile(username);
    }

    public function new(username:String, data:MiniProfileData)
    {
        super();
        this.username = username;

        title = Dictionary.getPhrase(MINIPROFILE_DIALOG_TITLE(username));
        usernameLabel.text = StringUtils.capitalize(username);
        Utils.updateStatusLabel(statusLabel, data.status);

        var tree:BalancedTree<Float, EloData> = new BalancedTree();
           
        for (tc => gamesCnt in data.gamesCntByTimeControl.keyValueIterator())
        {
            var key:Float = eloOrdinalNumber(gamesCnt, tc);
            var data:EloData = {timeControl: tc, elo: data.elo.get(tc)};
            tree.set(key, data);
        }

        for (data in tree)
            elosBox.addComponent(new TCEloEntry(data));

        if (FollowManager.getFollowedPlayerLogin() == username)
            followBtn.hidden = true;
        else
            unfollowBtn.hidden = true;

        if (data.isFriend)
            friendBtn.hidden = true;
        else
            unfriendBtn.hidden = true;

        if (SceneManager.playerInGame())
            btnBar.disabled = true;

        resize();
        SceneManager.addResizeHandler(resize);
    }
}