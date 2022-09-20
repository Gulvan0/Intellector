package gfx.basic_components;

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
        super.set_percentHeight(null);
        super.set_componentHeight(null);
        return super.set_componentWidth(value);
    }

    private override function set_componentHeight(value:Null<Float>):Null<Float> 
    {
        widthBased = false;
        super.set_percentWidth(null);
        super.set_componentWidth(null);
        return super.set_componentHeight(value);
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();
        if (widthBased)
        {
            var newHeight = width * originalHeight / originalWidth;
            if (height != newHeight)
                height = newHeight;
        }
        else
        {
            var newWidth = height * originalWidth / originalHeight;
            if (width != newWidth)
                width = newWidth;
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