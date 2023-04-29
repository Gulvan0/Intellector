package gfx.live.analysis;

import GlobalBroadcaster.GlobalEvent;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.interfaces.IGameScreen;
import gfx.live.models.ReadOnlyModel;
import GlobalBroadcaster.IGlobalEventObserver;
import gfx.live.interfaces.IGameComponent;
import gfx.live.common.action_bar.ActionBar;

class AnalysisActionBar extends ActionBar implements IGameComponent implements IGlobalEventObserver
{
    private final compact:Bool;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen):Void
    {
        if (compact)
            updateButtonSets([[ChangeOrientation, EditPosition, Share, PlayFromPos, PrevMove, NextMove]]);
        else
            updateButtonSets([[ChangeOrientation, EditPosition, Share, PlayFromPos]]);

        if (!LoginManager.isLogged())
            setBtnDisabled(PlayFromPos, true);

        eventHandler = gameScreen.handleActionBarEvent;
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

    public function asComponent():Component
    {
        return this;
    }


    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn:
                setBtnDisabled(PlayFromPos, false);
            case LoggedOut:
                setBtnDisabled(PlayFromPos, true);
        }
    }

    public function new(compact:Bool)
    {
        super();
        this.compact = compact;
    }
}