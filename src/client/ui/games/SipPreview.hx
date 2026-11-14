package client.ui.games;

import client.logic.challenge.creation.ChallengeDraftRules;
import client.ui.common.challenges.PositionPreviewPopover;
import haxe.ui.components.Button;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.LocaleUtils;
import intellectorboard.position.Position;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.Node;
import morestd.Detachable;

/**
    The result table's "Preview" buttons: the position of a custom starting SIP beside its button,
    one at a time. A press outside the preview and its button or Esc closes it.
**/
class SipPreview
{
    private static final PLACEMENT:AnchorPlacement = {side: Right, align: Start};

    private var toggle:Null<Button> = null;
    private var popover:Null<PositionPreviewPopover> = null;
    private var anchoring:Null<Detachable> = null;

    public function new() {}

    /** A Preview button for `sip`; null for a SIP that describes no position **/
    public function createToggle(sip:String):Null<Button>
    {
        var position:Null<Position> = ChallengeDraftRules.parseSip(sip);
        if (position == null)
            return null;

        var button:Null<Button> = null;
        button = new Button();
        button.toggle = true;
        button.text = LocaleUtils.localeBinding("intellector.games_widget.preview");
        button.addClass(StyleClass.CHALLENGE_PREVIEW_TOGGLE);
        button.verticalAlign = "center";
        button.onChange = _ -> {
            if (button.selected)
                open(button, position);
            else if (toggle == button)
                close();
        };
        return button;
    }

    public function close():Void
    {
        if (anchoring != null)
            anchoring.detach();
        anchoring = null;
        popover = null;

        var shownToggle:Null<Button> = toggle;
        toggle = null;
        if (shownToggle != null)
            shownToggle.selected = false;

        Browser.document.removeEventListener("pointerdown", onDocumentPointerDown, true);
        Browser.document.removeEventListener("keydown", onDocumentKeyDown);
    }

    private function open(button:Button, position:Position):Void
    {
        close();
        toggle = button;
        popover = new PositionPreviewPopover(position, position.turnColor);
        anchoring = Anchoring.attachOnScreen(popover, button, PLACEMENT);
        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);
        Browser.document.addEventListener("keydown", onDocumentKeyDown);
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        var target:Node = cast event.target;
        var buttonElement:Null<Element> = toggle != null ? toggle.element : null;
        if ((popover != null && popover.element.contains(target)) || (buttonElement != null && buttonElement.contains(target)))
            return;
        close();
    }

    private function onDocumentKeyDown(event:KeyboardEvent):Void
    {
        if (event.key == "Escape")
            close();
    }
}
