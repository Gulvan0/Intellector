package gfx.profile.simple_components;

import utils.StringUtils;
import dict.Utils;
import utils.AssetManager;
import gfx.basic_components.GenAnnotatedImage;
import gfx.profile.data.FriendData;

class FriendListEntry extends GenAnnotatedImage<FriendData>
{
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
    
    public function new(data:FriendData)
    {
        super(data, Auto, Percent(100), 0.08, 0.35, false);
    }
}