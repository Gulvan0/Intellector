package gfx.basic_components;

import haxe.ui.components.Spacer;

class Spacers
{
    public static function fullWidth():Spacer 
    {
        var spacer:Spacer = new Spacer();
        spacer.percentWidth = 100;
        return spacer;
    }

    public static function fullHeight():Spacer 
    {
        var spacer:Spacer = new Spacer();
        spacer.percentHeight = 100;
        return spacer;
    }
}