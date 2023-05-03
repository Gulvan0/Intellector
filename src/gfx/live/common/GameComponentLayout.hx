package gfx.live.common;

import gfx.live.events.ModelUpdateEvent;
import gfx.live.interfaces.IGameScreen;
import gfx.live.models.ReadOnlyModel;
import gfx.live.interfaces.IGameComponent;
import haxe.ui.containers.Box;

abstract class GameComponentLayout extends Box implements IGameComponent
{
    private abstract function getChildGameComponents():Array<IGameComponent>;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen)
    {
        for (component in getChildGameComponents())
            component.init(model, gameScreen);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        for (component in getChildGameComponents())
            component.handleModelUpdate(model, event);
    }

    public function destroy()
    {
        for (component in getChildGameComponents())
            component.destroy();
    }
    
    public function asComponent():Component
    {
        return this;
    }
    
    public function new()
    {
        super();
    }
}