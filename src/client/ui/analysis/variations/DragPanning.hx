package client.ui.analysis.variations;

import js.Browser;
import js.html.Element;
import js.html.MouseEvent;
import js.html.PointerEvent;

/**
    Click-and-drag scrolling of `element` with the mouse, starting anywhere inside it, nodes included.
    A drag begins past a small threshold and swallows the click it would end with. Touch is left to the
    browser's native scrolling.
**/
class DragPanning
{
    private static inline final THRESHOLD:Float = 4;

    private final element:Element;
    private final onDraggingChanged:Bool->Void;

    private var pointerId:Null<Int> = null;
    private var startX:Float = 0;
    private var startY:Float = 0;
    private var startScrollLeft:Float = 0;
    private var startScrollTop:Float = 0;
    private var dragging:Bool = false;
    private var swallowClick:Bool = false;

    public function new(element:Element, onDraggingChanged:Bool->Void)
    {
        this.element = element;
        this.onDraggingChanged = onDraggingChanged;
        element.addEventListener("pointerdown", onPointerDown);
        element.addEventListener("pointermove", onPointerMove);
        element.addEventListener("pointerup", onPointerEnd);
        element.addEventListener("pointercancel", onPointerEnd);
        element.addEventListener("click", onClick, true);
    }

    private function onPointerDown(event:PointerEvent):Void
    {
        if (event.pointerType != "mouse" || event.button != 0 || pointerId != null)
            return;

        pointerId = event.pointerId;
        startX = event.clientX;
        startY = event.clientY;
        startScrollLeft = element.scrollLeft;
        startScrollTop = element.scrollTop;
        swallowClick = false;
    }

    private function onPointerMove(event:PointerEvent):Void
    {
        if (event.pointerId != pointerId)
            return;

        var deltaX:Float = event.clientX - startX;
        var deltaY:Float = event.clientY - startY;
        if (!dragging)
        {
            if (Math.sqrt(deltaX * deltaX + deltaY * deltaY) < THRESHOLD)
                return;
            setDragging(true);
            element.setPointerCapture(pointerId); // only now: capturing earlier would retarget a plain click
        }

        element.scrollLeft = Math.round(startScrollLeft - deltaX);
        element.scrollTop = Math.round(startScrollTop - deltaY);
    }

    private function onPointerEnd(event:PointerEvent):Void
    {
        if (event.pointerId != pointerId)
            return;

        pointerId = null;
        if (!dragging)
            return;

        setDragging(false);
        swallowClick = event.type == "pointerup";
        Browser.window.setTimeout(() -> swallowClick = false, 0); // in case no click follows
    }

    private function onClick(event:MouseEvent):Void
    {
        if (!swallowClick)
            return;

        swallowClick = false;
        event.stopPropagation();
        event.preventDefault();
    }

    private function setDragging(dragging:Bool):Void
    {
        this.dragging = dragging;
        Browser.document.body.style.userSelect = dragging ? "none" : "";
        if (dragging)
            Browser.window.getSelection().removeAllRanges();
        onDraggingChanged(dragging);
    }
}
