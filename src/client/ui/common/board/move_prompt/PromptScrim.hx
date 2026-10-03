package client.ui.common.board.move_prompt;

import js.Browser;
import js.html.DivElement;
import js.html.Element;
import js.html.WheelEvent;

/**
    A very light veil over the whole viewport, menu bar included, laid just under a prompt's own
    elements: a press on it reaches nothing underneath (the prompt treats it as a press outside
    itself), while the wheel still scrolls whatever is under the cursor.
**/
class PromptScrim
{
    private static inline final COLOR:String = "rgba(42, 33, 26, 0.1)";

    private static inline final LINE_HEIGHT_PIXELS:Float = 16;

    private final element:DivElement;

    /**
        Shows the scrim right under `firstPromptElement`, which must already be on screen.
    **/
    public function new(firstPromptElement:Element)
    {
        element = Browser.document.createDivElement();
        element.style.position = "fixed";
        element.style.left = "0";
        element.style.top = "0";
        element.style.width = "100vw";
        element.style.height = "100vh";
        element.style.background = COLOR;
        element.addEventListener("wheel", onWheel);

        firstPromptElement.parentElement.insertBefore(element, firstPromptElement);
    }

    public function remove():Void
    {
        element.removeEventListener("wheel", onWheel);
        element.remove();
    }

    /*
        The browser only scrolls what's under the cursor natively, and here that's the scrim: the
        scroll is applied by hand to the nearest scrollable element beneath it.
    */
    private function onWheel(e:WheelEvent):Void
    {
        element.style.pointerEvents = "none";
        var beneath:Null<Element> = Browser.document.elementFromPoint(e.clientX, e.clientY);
        element.style.pointerEvents = "";

        var scrollable:Null<Element> = beneath;
        while (scrollable != null && !canScroll(scrollable))
            scrollable = scrollable.parentElement;

        if (scrollable == null)
            return;

        var unit:Float = switch e.deltaMode {
            case WheelEvent.DOM_DELTA_LINE: LINE_HEIGHT_PIXELS;
            case WheelEvent.DOM_DELTA_PAGE: scrollable.clientHeight;
            default: 1;
        }
        scrollable.scrollBy({left: e.deltaX * unit, top: e.deltaY * unit});
        e.preventDefault();
    }

    private static function canScroll(element:Element):Bool
    {
        var overflowY:String = Browser.window.getComputedStyle(element).overflowY;
        return (overflowY == "auto" || overflowY == "scroll") && element.scrollHeight > element.clientHeight;
    }
}
