package gfx.profile.simple_components;

import net.shared.EloValue.eloToStr;
import dict.Utils;
import utils.AssetManager;
import gfx.basic_components.GenAnnotatedImage;
import gfx.profile.data.EloData;

class TCEloEntry extends GenAnnotatedImage<EloData>
{
    private function generateLabelText(data:EloData):String
    {
        return eloToStr(data.elo);
    } 

    private function generateImagePath(data:EloData):String
    {
        return AssetManager.timeControlPath(data.timeControl);
    }

    private function generateImageTooltip(data:EloData):Null<String>
    {
        return data.timeControl == Correspondence? Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME) : data.timeControl.getName(); //TODO: Replace
    }
    
    public function new(data:EloData)
    {
        super(data, Exact(85), Exact(35));
    }
}