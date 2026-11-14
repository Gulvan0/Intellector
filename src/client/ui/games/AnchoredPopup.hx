package client.ui.games;

import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxefolio.AnchorAlign;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.ByMenuLayout;
import haxefolio.ElementShadow;
import js.Browser;
import js.html.Event;
import js.html.Node;
import morestd.Detachable;

/**
    A list popup placed below its anchor, the anchor's child outside its layout. Closed by a press
    outside the anchor or by `close`.
**/
class AnchoredPopup extends VBox
{
    private static inline final Z_INDEX:String = "20";

    private final anchor:Box;
    private final align:AnchorAlign;

    private var anchoring:Null<Detachable> = null;

    public var isOpen(get, never):Bool;

    /** Runs after every closing **/
    public var onClosed:Null<Void->Void> = null;

    /** `align`: which of the anchor's edges the popup lines up with **/
    public function new(anchor:Box, popupWidth:Float, align:AnchorAlign)
    {
        super();
        this.anchor = anchor;
        this.align = align;
        width = popupWidth;
        includeInLayout = false;
        hidden = true;
        addClass(StyleClass.FILTER_POPUP);
        element.style.zIndex = Z_INDEX;
        ElementShadow.apply(element, StyleVars.FILTER_POPUP_SHADOW);
        anchor.addComponent(this);
    }

    public function toggle():Void
    {
        if (isOpen)
            close();
        else
            open();
    }

    public function open():Void
    {
        if (isOpen)
            return;

        hidden = false;
        var placement:AnchorPlacement = {side: Below, align: align};
        anchoring = Anchoring.attach(this, anchor, ByMenuLayout.fromValue(placement));
        Browser.document.addEventListener("pointerdown", onDocumentPointerDown, true);
    }

    public function close():Void
    {
        if (!isOpen)
            return;

        hidden = true;
        if (anchoring != null)
            anchoring.detach();
        anchoring = null;
        Browser.document.removeEventListener("pointerdown", onDocumentPointerDown, true);
        if (onClosed != null)
            onClosed();
    }

    private function get_isOpen():Bool
    {
        return !hidden;
    }

    private function onDocumentPointerDown(event:Event):Void
    {
        var target:Node = cast event.target;
        if (!anchor.element.contains(target))
            close();
    }
}
