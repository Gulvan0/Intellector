package tests.ui.utils.components;

import utils.MathUtils;
import haxe.ui.events.UIEvent;
import haxe.ui.core.Component;
import haxe.ui.containers.VBox;

enum Dimension
{
    Width;
    Height;
}

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/testenv/adjustablecontentbox.xml"))
class AdjustableContentBox extends VBox
{
    private function setDimension(dim:Dimension, value:Null<Float>)
    {
        switch dim 
        {
            case Width:
                if (value != null)
                {
                    componentContainer.width = value;
                    widthLabel.text = Std.string(Math.round(value));
                }
                else
                    widthLabel.text = '#';
            case Height:
                if (value != null)
                {
                    componentContainer.height = value;
                    heightLabel.text = Std.string(Math.round(value));
                }
                else
                    heightLabel.text = '#';
        }
    }

    @:bind(widthSlider, UIEvent.CHANGE)
    private function onWidthChanged(e) 
    {
        if (widthLabel.text != '#')
            setDimension(Width, widthSlider.pos);
    }

    @:bind(heightSlider, UIEvent.CHANGE)
    private function onHeightChanged(e) 
    {
        if (heightLabel.text != '#')
            setDimension(Height, heightSlider.pos);
    }

    private function initAdjuster(dimension:Dimension, minValue:Float, maxValue:Float)
    {
        var slider = dimension == Width? widthSlider : heightSlider;

        if (minValue > 0 && maxValue > minValue)
        {
            var initialValue:Float = MathUtils.avg(minValue, maxValue);
            slider.min = minValue;
            slider.max = maxValue;
            slider.pos = initialValue;
            setDimension(dimension, initialValue);
        }
        else
        {
            slider.min = 0;
            slider.max = 100;
            slider.pos = 50;
            setDimension(dimension, null);
            slider.disabled = true;
        }
    }

    public function new(component:Component, minWidth:Float, maxWidth:Float, minHeight:Float, maxHeight:Float) 
    {
        super();
        
        initAdjuster(Width, minWidth, maxWidth);
        initAdjuster(Height, minHeight, maxHeight);
        componentContainer.addComponent(component);
    }
}