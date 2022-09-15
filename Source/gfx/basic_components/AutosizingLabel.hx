package gfx.basic_components;

import gfx.basic_components.utils.TextAlign;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;

class AutosizingLabel extends Label
{
    public var minFontSize:Null<Float> = null;
    public var maxFontSize:Null<Float> = null;
    public var sizePerCharWidth:Float = 2.1;
    public var sizePerCharHeight:Float = 0.758;
    public var align:TextAlign = Center;
    public var lengthGetter:Label->Int = label -> label.text.length;

    private override function validateComponentLayout():Bool 
    {
        var b:Bool = super.validateComponentLayout();

        validateFontSize();

        return b;
    }

    public function validateFontSize()
    {
        var fontSize:Float;
        if (autoWidth)
            fontSize = sizePerCharHeight * height;
        else if (autoHeight)
            fontSize = sizePerCharWidth * width / lengthGetter(this);
        else
            fontSize = Math.min(sizePerCharWidth * width / lengthGetter(this), sizePerCharHeight * height);

        if (minFontSize != null)
            fontSize = Math.max(fontSize, minFontSize);

        if (maxFontSize != null)
            fontSize = Math.min(fontSize, maxFontSize);

        var newStyle:Style = customStyle.clone();
        newStyle.fontSize = fontSize;
        newStyle.textAlign = align;
        customStyle = newStyle;
    }
}