package gfx.game.common.action_bar;

import haxe.ui.core.Component;
import gfx.basic_components.Gallery;
import dict.Phrase;
import gfx.game.events.ActionBarEvent;
import haxe.ui.containers.VBox;
import net.shared.dataobj.OfferKind;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/action_bar.xml"))
class ActionBar extends VBox
{
    private var buttonBars:Array<ActionButtons> = [];
    private var requestBoxes:Map<OfferKind, RequestBox> = [];

    private var requestActive:Map<OfferKind, Bool> = [Draw => false, Takeback => false];
    private var eventHandler:ActionBarEvent->Void;

    private function displayRequestBox(request:OfferKind)
    {
        if (requestActive.get(request))
            return;

        requestBoxes.get(request).hidden = false;

        requestActive.set(request, true);

        if (request == Takeback && requestActive.get(Draw))
            requestBoxes.get(Draw).hidden = true;
    }

    private function hideRequestBox(request:OfferKind)
    {
        if (!requestActive.get(request))
            return;

        requestBoxes.get(request).hidden = true;

        requestActive.set(request, false);

        if (request == Takeback && requestActive.get(Draw))
            requestBoxes.get(Draw).hidden = false;
    }

    private function onRequestAccepted(request:OfferKind)
    {
        hideRequestBox(request);
        eventHandler(IncomingOfferAccepted(request));
    }

    private function onRequestDeclined(request:OfferKind)
    {
        hideRequestBox(request);
        eventHandler(IncomingOfferDeclined(request));
    }

    private function onButtonPressed(button:ActionButton)
    {
        eventHandler(ActionButtonPressed(button));
    }

    private function questionByOfferKind(offerKind:OfferKind):Phrase
    {
        return switch offerKind 
        {
            case Draw: DRAW_QUESTION_TEXT;
            case Takeback: TAKEBACK_QUESTION_TEXT;
        }
    }

    private function replaceButton(oldBtn:ActionButton, newBtn:ActionButton)
    {
        for (bar in buttonBars)
            bar.replaceButton(oldBtn, newBtn);
    }

    private function setBtnDisabled(button:ActionButton, disabled:Bool)
    {
        for (bar in buttonBars)
            bar.setBtnDisabled(button, disabled);
    }

    public function asComponent():Component
    {
        return this;
    }

    private function updateButtonSets(buttonSets:Array<Array<ActionButton>>)
    {
        buttonsContainer.removeAllComponents();

        if (buttonSets.length > 1)
        {
            var gallery:Gallery = new Gallery();
            buttonsContainer.addComponent(gallery);
            
            for (buttonSet in buttonSets)
            {
                var buttonRow:ActionButtons = new ActionButtons();
                buttonRow.btnPressHandler = onButtonPressed;
                buttonRow.setButtons(buttonSet);

                gallery.addComponent(buttonRow);
                buttonBars.push(buttonRow);
            }
        }
        else
        {
            var buttonRow:ActionButtons = new ActionButtons();
            buttonRow.btnPressHandler = onButtonPressed;
            buttonRow.setButtons(buttonSets[0]);

            buttonsContainer.addComponent(buttonRow);
            buttonBars.push(buttonRow);
        }
    }

    public function new(?eventHandler:ActionBarEvent->Void, ?buttonSets:Array<Array<ActionButton>>)
    {
        super();

        if (eventHandler != null)
            this.eventHandler = eventHandler;

        if (buttonSets != null)
            updateButtonSets(buttonSets);

        for (offerKind in [Draw, Takeback])
        {
            var requestBox:RequestBox = new RequestBox(questionByOfferKind(offerKind), onRequestAccepted.bind(offerKind), onRequestDeclined.bind(offerKind));
            requestBox.hidden = true;
            requestBoxes.set(offerKind, requestBox);
            requestsContainer.addComponent(requestBox);
        }
    }
}