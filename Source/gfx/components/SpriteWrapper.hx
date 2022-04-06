package gfx.components;

import haxe.Timer;
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
        _sprite = new Sprite();
        var bounds = value.getBounds(value);
        value.x -= bounds.x;
        value.y -= bounds.y;
        _sprite.addChild(value);
        if (_sprite.width > 0) this.width = _sprite.width;
        if (_sprite.height> 0) this.height= _sprite.height;
        addChild(_sprite);
        Timer.delay(() -> {
            if (_sprite.width > 0) this.width = _sprite.width;
            if (_sprite.height> 0) this.height= _sprite.height;
            invalidateComponentLayout();
        }, 100);
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

    public function new() 
    {
        super();
    }
}