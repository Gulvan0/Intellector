package gfx.components;

import openfl.display.Sprite;
import haxe.ui.core.Component;

class SpriteWrapper extends Component 
{
    public var _sprite:Sprite = null;
    public var sprite(get, set):Sprite;

    private var offsetX:Float;
    private var offsetY:Float;

    private function get_sprite():Sprite {
        return _sprite;
    }
    private function set_sprite(value:Sprite):Sprite {
        _sprite = value;
        _sprite.x = offsetX;
        _sprite.y = offsetY;
        addChild(_sprite);
        invalidateComponentLayout();
        return value;
    }
    
    private override function validateComponentLayout():Bool {
        var b = super.validateComponentLayout();
        if (_sprite != null) {
            _sprite.width = this.width - offsetX;
            _sprite.height = this.height - offsetY;
        }
        return b;
    }

    public function new(?offsetX:Float = 0, ?offsetY:Float = 0) 
    {
        super();
        this.offsetX = offsetX;
        this.offsetY = offsetY;
    }
}