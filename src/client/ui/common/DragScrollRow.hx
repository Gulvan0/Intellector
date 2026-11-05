package client.ui.common;

import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxefolio.structure.SidewaysScroll;
import js.html.Element;
import js.html.MouseEvent;

/**
    A one-line row of items that scrolls sideways when they don't fit, without a scrollbar: by
    dragging it with a mouse, natively by touch. The edge where items are hidden fades out. A drag
    doesn't click the item it started on, and no click inside the row reaches the row's ancestors.
**/
class DragScrollRow extends Box
{
    private final content:HBox;
    private final scroller:Element;

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

        SidewaysScroll.attach(scroller);
        scroller.addEventListener("click", (event:MouseEvent) -> event.stopPropagation());
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
}
