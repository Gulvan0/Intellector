package gfx.profile;

import haxe.ui.styles.Style;
import gfx.profile.data.UserStatus;
import haxe.ui.components.Label;

class Utils
{
    public static function updateStatusLabel(label:Label, status:UserStatus) 
    {
        label.text = dict.Utils.getUserStatusText(status);
        
        var newStyle:Style = label.customStyle.clone();

        switch status 
        {
            case Offline(secondsSinceLastAction):
                newStyle.color = 0x333333;
            case Online:
                newStyle.color = 0x00FC00;
                newStyle.fontBold = true;
            case InGame:
                newStyle.color = 0xA52A2A;
                newStyle.fontBold = true;
        }

        label.customStyle = newStyle;
    }
}