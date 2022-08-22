package gfx.components;

import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import haxe.Timer;
import openfl.display.Sprite;
import haxe.ui.core.Component;

class SpriteWrapper extends Component 
{
    private var sprite:DisplayObjectContainer;

    public function syncDimensionsUpstream(?e)
    {
        this.width = sprite.width;
        this.height = sprite.height;
    }

    private function onAdded(e)
    {
        sprite.removeEventListener(Event.ADDED_TO_STAGE, onAdded);
        sprite.addEventListener(Event.ENTER_FRAME, syncDimensionsUpstream);
        sprite.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
    }

    private function onRemoved(e)
    {
        sprite.removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
        sprite.removeEventListener(Event.ENTER_FRAME, syncDimensionsUpstream);
    }

    public function new(sprite:DisplayObjectContainer, ?constantSize:Bool = true) 
    {
        super();
        this.sprite = sprite;
        addChild(sprite);
        if (constantSize)
            syncDimensionsUpstream();
        else
            sprite.addEventListener(Event.ADDED_TO_STAGE, onAdded);
    }
}