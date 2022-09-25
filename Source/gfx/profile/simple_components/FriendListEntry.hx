package gfx.profile.simple_components;

import net.Requests;
import haxe.ui.events.MouseEvent;
import utils.StringUtils;
import dict.Utils;
import utils.AssetManager;
import gfx.basic_components.GenAnnotatedImage;
import gfx.profile.data.FriendData;

class FriendListEntry extends GenAnnotatedImage<FriendData>
{
    private var playerLogin:String;

    private function generateLabelText(data:FriendData):String
    {
        return StringUtils.capitalize(data.login);
    } 

    private function generateImagePath(data:FriendData):String
    {
        return AssetManager.statusPath(data.status);
    }

    private function generateImageTooltip(data:FriendData):Null<String>
    {
        return Utils.getUserStatusText(data.status);
    }

    @:bind(lbl, MouseEvent.MOUSE_OVER)
    private function onHover(e)
    {
        lbl.setFontBold(true);
    }

    @:bind(lbl, MouseEvent.MOUSE_OUT)
    private function onOut(e)
    {
        lbl.setFontBold(false);
    }

    @:bind(lbl, MouseEvent.CLICK)
    private function onClicked(e)
    {
        Requests.getMiniProfile(playerLogin);
    }
    
    public function new(data:FriendData)
    {
        super(data, Auto, Percent(100), 0.08, 0.35, false);
        this.playerLogin = data.login;

        lbl.enablePointerEvents();
    }
}