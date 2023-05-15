package gfx.profile.simple_components;

import utils.StringUtils.eloToStr;
import dict.Utils;
import assets.Paths;
import gfx.basic_components.GenAnnotatedImage;
import gfx.profile.data.EloData;
import dict.Dictionary;

class TCEloEntry extends GenAnnotatedImage<EloData>
{
    private function generateLabelText(data:EloData):String
    {
        return eloToStr(data.elo);
    } 

    private function generateImagePath(data:EloData):String
    {
        return Paths.timeControl(data.timeControl);
    }

    private function generateImageTooltip(data:EloData):Null<String>
    {
        return Utils.getTimeControlTypeName(data.timeControl);
    }
    
    public function new(data:EloData)
    {
        super(data, Exact(100), Exact(35));
    }
}