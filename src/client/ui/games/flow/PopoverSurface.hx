package client.ui.games.flow;

import haxe.ui.Toolkit;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.ElementShadow;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.Node;
import morestd.Detachable;

/**
    The Wide steps: a popover under the condition being built, and a prompt beside the option that
    opened it. A press outside both or Esc cancels; Backspace goes back while the step holds no text.
    Nothing reacts while a modal (the player search) covers `page`.
**/
class PopoverSurface implements StepSurface
{
    private static final BELOW:AnchorPlacement = {side: Below, align: Start};
    private static final BESIDE:AnchorPlacement = {side: Right, align: Start};

    private final page:Component;
    private final onCancelled:Void->Void;
    private final card:VBox;
    private final promptCard:VBox;

    private var anchor:Component;
    private var anchoring:Null<Detachable> = null;
    private var promptAnchoring:Null<Detachable> = null;
    private var step:Null<FlowStep> = null;
    private var promptStep:Null<FlowStep> = null;

    public function new(page:Component, anchor:Component, onCancelled:Void->Void)
    {
        this.page = page;
        this.anchor = anchor;
        this.onCancelled = onCancelled;
        card = createCard();
        promptCard = createCard();

        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);
        Browser.document.addEventListener("keydown", onDocumentKeyDown);
    }

    public function show(step:FlowStep):Void
    {
        closePrompt();
        this.step = step;
        fill(card, step);
        if (anchoring == null)
            anchoring = Anchoring.attachOnScreen(card, anchor, BELOW);
        Toolkit.callLater(step.onShown);
    }

    public function showPrompt(step:FlowStep, option:Component):Void
    {
        closePrompt();
        promptStep = step;
        fill(promptCard, step);
        promptAnchoring = Anchoring.attachOnScreen(promptCard, option, BESIDE);
        Toolkit.callLater(step.onShown);
    }

    public function closePrompt():Void
    {
        if (promptAnchoring != null)
            promptAnchoring.detach();
        promptAnchoring = null;
        promptStep = null;
    }

    public function reanchor(anchor:Component):Void
    {
        this.anchor = anchor;
        if (anchoring == null)
            return;
        anchoring.detach();
        anchoring = Anchoring.attachOnScreen(card, anchor, BELOW);
    }

    public function close():Void
    {
        closePrompt();
        if (anchoring != null)
            anchoring.detach();
        anchoring = null;
        step = null;
        Browser.document.removeEventListener("pointerdown", onDocumentPointerDown, true);
        Browser.document.removeEventListener("keydown", onDocumentKeyDown);
    }

    private static function createCard():VBox
    {
        var card:VBox = new VBox();
        card.addClass(StyleClass.GAMES_STEP_CARD);
        ElementShadow.apply(card.element, StyleVars.FILTER_POPUP_SHADOW);
        return card;
    }

    private static function fill(card:VBox, step:FlowStep):Void
    {
        card.removeAllComponents(false);
        if (step.title != null)
            card.addComponent(new StepHeader(step.title, step.back));
        card.addComponent(step.content);
        if (step.footer != null)
            card.addComponent(step.footer);
    }

    private function cancel():Void
    {
        close();
        onCancelled();
    }

    private function underModal():Bool
    {
        var element:Null<Element> = page.element.closest("[inert]");
        return element != null;
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        var target:Node = cast event.target;
        if (underModal() || card.element.contains(target) || (promptStep != null && promptCard.element.contains(target)))
            return;
        cancel();
    }

    private function onDocumentKeyDown(event:KeyboardEvent):Void
    {
        if (underModal())
            return;

        if (event.key == "Escape")
        {
            event.preventDefault();
            cancel();
            return;
        }

        var current:Null<FlowStep> = promptStep ?? step;
        if (event.key == "Backspace" && current != null && current.back != null && !current.holdsText())
        {
            event.preventDefault();
            current.back();
        }
    }
}
