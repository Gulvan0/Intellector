package client.ui.common;

import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import js.Browser;
import js.html.Element;
import js.html.MouseEvent;
import js.html.PointerEvent;

/**
    A one-line row of items that scrolls sideways when they don't fit, without a scrollbar: by
    dragging it with a mouse, natively by touch. The edge where items are hidden fades out. A drag
    doesn't click the item it started on, and no click inside the row reaches the row's ancestors.
**/
class DragScrollRow extends Box
{
    private static inline final DRAG_THRESHOLD_PX:Float = 4;
    private static inline final FADE_PX:Int = 24;

    private final content:HBox;
    private final scroller:Element;

    private var pressX:Null<Float> = null;
    private var pressScrollLeft:Float = 0;
    private var dragging:Bool = false;
    private var suppressClick:Bool = false;

    public function new()
    {
        super();
        addClass(StyleClass.DRAG_SCROLL_ROW);

        content = new HBox();
        content.addClass(StyleClass.DRAG_SCROLL_ROW_CONTENT);
        addComponent(content);

        scroller = element;
        scroller.style.overflowX = "auto";
        scroller.style.overflowY = "hidden";
        scroller.style.setProperty("scrollbar-width", "none");

        scroller.addEventListener("pointerdown", onPointerDown);
        scroller.addEventListener("scroll", refreshFades);
        scroller.addEventListener("click", onClickCapture, true);
        scroller.addEventListener("click", (event:MouseEvent) -> event.stopPropagation());
        js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> refreshFades()).observe(scroller);
    }

    public function addItem(item:Component):Void
    {
        content.addComponent(item);
    }

    public function clearItems():Void
    {
        content.removeAllComponents();
        scroller.scrollLeft = 0;
    }

    private function onPointerDown(event:PointerEvent):Void
    {
        suppressClick = false;
        if (event.pointerType != "mouse" || event.button != 0 || !isScrollable())
            return;

        pressX = event.clientX;
        pressScrollLeft = scroller.scrollLeft;
        dragging = false;
        Browser.window.addEventListener("pointermove", onPointerMove);
        Browser.window.addEventListener("pointerup", onPointerUp);
    }

    private function onPointerMove(event:PointerEvent):Void
    {
        if (pressX == null)
            return;

        var shift:Float = event.clientX - pressX;
        if (!dragging && Math.abs(shift) > DRAG_THRESHOLD_PX)
        {
            dragging = true;
            scroller.style.cursor = "grabbing";
        }
        if (dragging)
            scroller.scrollLeft = Std.int(pressScrollLeft - shift);
    }

    private function onPointerUp(_:PointerEvent):Void
    {
        Browser.window.removeEventListener("pointermove", onPointerMove);
        Browser.window.removeEventListener("pointerup", onPointerUp);
        suppressClick = dragging;
        dragging = false;
        pressX = null;
        refreshFades();
    }

    private function onClickCapture(event:MouseEvent):Void
    {
        if (!suppressClick)
            return;

        suppressClick = false;
        event.stopPropagation();
        event.preventDefault();
    }

    private function isScrollable():Bool
    {
        return scroller.scrollWidth > scroller.clientWidth + 1;
    }

    private function refreshFades():Void
    {
        var hiddenLeft:Bool = scroller.scrollLeft > 1;
        var hiddenRight:Bool = scroller.scrollLeft + scroller.clientWidth < scroller.scrollWidth - 1;
        var start:String = hiddenLeft ? 'transparent 0, black ${FADE_PX}px' : "black 0";
        var end:String = hiddenRight ? 'black calc(100% - ${FADE_PX}px), transparent 100%' : "black 100%";
        var mask:String = 'linear-gradient(to right, $start, $end)';
        scroller.style.setProperty("mask-image", mask);
        scroller.style.setProperty("-webkit-mask-image", mask);
        if (!dragging)
            scroller.style.cursor = isScrollable() ? "grab" : "";
    }
}
