package gfx.live.common.action_bar;

import gfx.live.events.ActionBarEvent;
import haxe.ui.containers.VBox;

class ActionBar extends VBox
{
    private var buttonBars:Array<ActionButtons> = [];
    private var requestBoxes:Map<OfferKind, RequestBox> = [];

    private var eventHandler:ActionBarEvent->Void;

    private function displayRequestBox(request:OfferKind)
    {
        //TODO
    }

    private function hideRequestBox(request:OfferKind)
    {
        //TODO
    }

    private function onRequestAccepted(request:OfferKind)
    {
        eventHandler(IncomingOfferAccepted(request));
    }

    private function onRequestDeclined(request:OfferKind)
    {
        eventHandler(IncomingOfferDeclined(request));
    }

    private function onButtonPressed(button:ActionButton)
    {
        eventHandler(ActionButtonPressed(button));
    }

    public function new(buttonSets:Array<Array<ActionButton>>, eventHandler:ActionBarEvent->Void)
    {
        super();
        this.eventHandler = eventHandler;

        //TODO
    }
}