package gfx.basic_components;

import gfx.basic_components.utils.DimValue;

abstract class GenAnnotatedImage<T> extends AnnotatedImage
{
    private abstract function generateLabelText(key:T):String;
    private abstract function generateImagePath(key:T):String;
    private abstract function generateImageTooltip(key:T):Null<String>;

    public function new(key:T, w:DimValue, h:DimValue, ?spacingPerHeightUnit:Float, ?imageScaleFactor:Float, ?squareImage:Bool)
    {
        super(w, h, generateImagePath(key), generateLabelText(key), generateImageTooltip(key), spacingPerHeightUnit, imageScaleFactor, squareImage);
    }
}