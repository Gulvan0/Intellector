package gfx.game.common;

import gfx.game.interfaces.IGameScreenGetters;
import haxe.ui.core.Component;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Box;

abstract class GameComponentLayout extends Box implements IGameComponent
{
    private abstract function getChildGameComponents():Array<IGameComponent>;

    private function beforeUpdateProcessedByChildren(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        //* Do nothing (override if needed)
    }

    private function afterUpdateProcessedByChildren(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        //* Do nothing (override if needed)
    }

    private function beforeChildrenInitialized(model:ReadOnlyModel, getters:IGameScreenGetters)
    {
        //* Do nothing (override if needed)
    }
    
    private function afterChildrenInitialized(model:ReadOnlyModel, getters:IGameScreenGetters)
    {
        //* Do nothing (override if needed)
    }

    private function destroyLayout()
    {
        //* Do nothing (override if needed)
    }

    public function init(model:ReadOnlyModel, getters:IGameScreenGetters)
    {
        beforeChildrenInitialized(model, getters);

        for (component in getChildGameComponents())
            component.init(model, getters);
        
        afterChildrenInitialized(model, getters);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        beforeUpdateProcessedByChildren(model, event);

        for (component in getChildGameComponents())
            component.handleModelUpdate(model, event);

        afterUpdateProcessedByChildren(model, event);
    }

    public function destroy()
    {
        for (component in getChildGameComponents())
            component.destroy();
        
        destroyLayout();
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