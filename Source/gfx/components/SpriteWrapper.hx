package gfx.components;

import haxe.Timer;
import openfl.display.Sprite;
import haxe.ui.core.Component;

class SpriteWrapper extends Component 
{
    private var _originalSprite:Sprite;
    public var _sprite:Sprite = null;
    public var sprite(get, set):Sprite;
    public var autoDownstreamSync:Bool = true;

    private function get_sprite():Sprite {
        return _sprite;
    }
    private function set_sprite(value:Sprite):Sprite {
        _originalSprite = value;
        _sprite = new Sprite();
        _sprite.addChild(_originalSprite);
        refreshLayout();
        addChild(_sprite);
        Timer.delay(() -> {
            syncDimensionsUpstream();
            invalidateComponentLayout();
        }, 100);
        return _originalSprite;
    }
    
    private override function validateComponentLayout():Bool {
        var b = super.validateComponentLayout();
        if (_sprite != null && autoDownstreamSync) 
            syncDimensionsDownstream();
        return b;
    }

    public function refreshLayout()
    {
        var bounds = _originalSprite.getBounds(_sprite);
        _originalSprite.x -= bounds.x;
        _originalSprite.y -= bounds.y;
        syncDimensionsUpstream();
    }

    public function syncDimensionsUpstream()
    {
        if (_sprite.width > 0) this.width = _sprite.width;
        if (_sprite.height> 0) this.height= _sprite.height;
    }

    public function syncDimensionsDownstream()
    {
        _sprite.width = this.width;
        _sprite.height = this.height;
    }

    public function new() 
    {
        super();
    }
}