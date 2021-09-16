package gfx.components;

import openfl.display.Sprite;
import haxe.ui.core.Component;

class SpriteWrapper extends Component 
{
    public var _sprite:Sprite = null;
    public var sprite(get, set):Sprite;
    private function get_sprite():Sprite {
        return _sprite;
    }
    private function set_sprite(value:Sprite):Sprite {
        _sprite = value;
        addChild(_sprite);
        invalidateComponentLayout();
        return value;
    }
    
    private override function validateComponentLayout():Bool {
        var b = super.validateComponentLayout();
        if (_sprite != null) {
            _sprite.width = this.width;
            _sprite.height = this.height;
        }
        return b;
    }
}