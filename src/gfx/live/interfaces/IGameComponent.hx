package gfx.live.interfaces;

import haxe.ui.core.Component;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.models.ReadOnlyModel;

interface IGameComponent 
{
    public function init(model:ReadOnlyModel, gameScreen:IGameComponentObserver):Void;
    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void;
    public function destroy():Void;
    public function asComponent():Component;
}