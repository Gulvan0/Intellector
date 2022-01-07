package gfx.components;

import openfl.display.Sprite;

class OffsettedSprite extends Sprite
{
    private var xOffset:Float;
    private var yOffset:Float;

    public var left(get, never):Float;
    public var top(get, never):Float;
    public var right(get, never):Float;
    public var bottom(get, never):Float;

    public function get_left():Float
    {
        return x + xOffset;
    }

    public function get_top():Float
    {
        return x + yOffset;
    }

    public function get_right():Float
    {
        return x + xOffset + width;
    }

    public function get_bottom():Float
    {
        return x + yOffset + height;
    }

    public function new(xOffset:Float, yOffset:Float) 
    {
        super();
        
        this.xOffset = xOffset;
        this.yOffset = yOffset;
    }
}