package gfx.profile.simple_components;

import dict.Dictionary;
import utils.AssetManager;
import gfx.basic_components.GenAnnotatedImage;
import gfx.profile.data.FriendData;

class FriendListEntry extends GenAnnotatedImage<FriendData>
{
    private function generateLabelText(data:FriendData):String
    {
        return data.login;
    } 

    private function generateImagePath(data:FriendData):String
    {
        return AssetManager.statusPath(data.status);
    }

    private function generateImageTooltip(data:FriendData):Null<String>
    {
        return Dictionary.getPhrase(PROFILE_STATUS_TEXT(data.status));
    }
    
    public function new(data:FriendData)
    {
        super(data, Auto, Percent(100), true);
    }
}