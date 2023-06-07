package gfx.game.interfaces;

import haxe.ui.core.Component;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;

interface IGameComponent 
{
    public function init(model:ReadOnlyModel, getters:IGameScreenGetters):Void;
    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void;
    public function destroy():Void;
    public function asComponent():Component;
}