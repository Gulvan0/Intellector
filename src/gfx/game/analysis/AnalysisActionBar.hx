package gfx.game.analysis;

import gfx.game.interfaces.IGameScreenGetters;
import haxe.ui.core.Component;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import GlobalBroadcaster.IGlobalEventObserver;
import gfx.game.interfaces.IGameComponent;
import gfx.game.common.action_bar.ActionBar;

class AnalysisActionBar extends ActionBar implements IGameComponent implements IGlobalEventObserver
{
    private final compact:Bool;

    public function init(model:ReadOnlyModel, getters:IGameScreenGetters):Void
    {
        if (compact)
            updateButtonSets([[ChangeOrientation, EditPosition, Share, PlayFromHere, PrevMove, NextMove]]);
        else
            updateButtonSets([[ChangeOrientation, EditPosition, Share, PlayFromHere]]);

        if (!LoginManager.isLogged())
            setBtnDisabled(PlayFromHere, true);

        getBehaviour = getters.getBehaviour;
        GlobalBroadcaster.addObserver(this);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        //* Do nothing (doesn't react to any model event)
    }

    public function destroy():Void
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn:
                setBtnDisabled(PlayFromHere, false);
            case LoggedOut:
                setBtnDisabled(PlayFromHere, true);
            default:
        }
    }

    public function new(compact:Bool)
    {
        super();
        this.compact = compact;
    }
}