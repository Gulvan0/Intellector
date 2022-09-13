package gfx.basic_components;

import haxe.ui.styles.Style;
import haxe.ui.components.Label;

class AutosizingLabel extends Label
{
    public var minFontSize:Float = 10;
    public var sizePerCharWidth:Float = 1.8;
    public var targetWidth:Float = 100;
    public var lengthGetter:Label->Int = label -> label.text.length;

    private override function validateComponentLayout():Bool 
    {
        var b:Bool = super.validateComponentLayout();

        validateFontSize();

        return b;
    }

    public function validateFontSize()
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontSize = Math.min(sizePerCharWidth * targetWidth / lengthGetter(this), minFontSize);
        customStyle = newStyle;
    }
}