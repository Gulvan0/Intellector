package gfx.components;

import haxe.ui.components.Image;

/**
    Aspect-ratio-preserving image
**/
class ARPImage extends Image
{
    private var widthBased:Bool = true;

    private override function set_componentWidth(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        return super.set_componentWidth(value);
    }

    private override function set_componentHeight(value:Null<Float>):Null<Float> 
    {
        widthBased = false;
        return super.set_componentHeight(value);
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        if (widthBased)
        {
            var newWidth = height * originalWidth / originalHeight;
            if (width != newWidth)
            {
                width = newWidth;
                invalidateComponent();
            }
        }
        else
        {
            var newHeight = width * originalHeight / originalWidth;
            if (height != newHeight)
            {
                height = newHeight;
                invalidateComponent();
            }
        }
        return b;
    }

    private override function set_percentWidth(value:Null<Float>):Null<Float> 
    {
        widthBased = true;
        return super.set_percentWidth(value);
    }

    private override function set_percentHeight(value:Null<Float>):Null<Float>
    {
        widthBased = false;
        return super.set_percentHeight(value);
    }
}