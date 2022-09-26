package gfx.basic_components;

import haxe.ui.events.UIEvent;
import gfx.basic_components.utils.TextAlign;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;

class AutosizingLabel extends Label
{
    public var minFontSize:Null<Float> = null;
    public var maxFontSize:Null<Float> = null;
    public var sizePerCharWidth:Float = 1.8;
    public var sizePerCharHeight:Float = 0.758;
    public var align:TextAlign = Center;
    public var lengthGetter:Label->Int = label -> label.text.length;

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        validateFontSize();
    }

    public function setFontBold(value:Bool)
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontBold = value;
        customStyle = newStyle;
    }

    public function enablePointerEvents()
    {
        var newStyle:Style = customStyle.clone();
        newStyle.pointerEvents = 'true';
        newStyle.backgroundColor = 0x000000;
        newStyle.backgroundOpacity = 0;
        customStyle = newStyle;
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