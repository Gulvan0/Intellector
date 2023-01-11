package gfx.basic_components;

import haxe.ui.components.Image;

/**
    Aspect-ratio-preserving image
**/
class ARPImage extends Image
{
    private var widthBased:Bool = true;

    private override function set_width(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        super.set_percentHeight(null);
        super.set_componentHeight(null);
        return super.set_width(value);
    }

    private override function set_height(value:Null<Float>):Null<Float> 
    {
        widthBased = false;
        super.set_percentWidth(null);
        super.set_componentWidth(null);
        return super.set_height(value);
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        if (widthBased)
        {
            var newHeight = width * originalHeight / originalWidth;
            if (height != newHeight)
                super.set_height(newHeight);
        }
        else
        {
            var newWidth = height * originalWidth / originalHeight;
            if (width != newWidth)
                super.set_width(newWidth);
        }
        return super.validateComponentLayout() || b;
    }

    private override function set_percentWidth(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        super.set_percentHeight(null);
        super.set_componentHeight(null);
        return super.set_percentWidth(value);
    }

    private override function set_percentHeight(value:Null<Float>):Null<Float>
    {
        widthBased = false;
        super.set_percentWidth(null);
        super.set_componentWidth(null);
        return super.set_percentHeight(value);
    }
}