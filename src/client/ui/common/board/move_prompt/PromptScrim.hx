package client.ui.common.board.move_prompt;

import js.Browser;
import js.html.DivElement;
import js.html.Element;
import js.html.WheelEvent;

/**
    A light veil over the whole viewport, just under a prompt: presses on it count as outside the
    prompt, while the wheel still scrolls whatever is under the cursor.
**/
class PromptScrim
{
    private final element:DivElement;

    /** Shows the scrim right under `firstPromptElement`, which must already be on screen **/
    public function new(firstPromptElement:Element)
    {
        element = Browser.document.createDivElement();
        element.style.position = "fixed";
        element.style.left = "0";
        element.style.top = "0";
        element.style.width = "100vw";
        element.style.height = "100vh";
        element.style.background = StyleVars.MOVE_PROMPT_SCRIM_COLOR;
        element.addEventListener("wheel", onWheel);

        firstPromptElement.parentElement.insertBefore(element, firstPromptElement);
    }

    public function remove():Void
    {
        element.removeEventListener("wheel", onWheel);
        element.remove();
    }

    // the scrim is what's under the cursor, so the scroll is passed by hand to what's beneath it
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
            case WheelEvent.DOM_DELTA_LINE: StyleVars.MOVE_PROMPT_SCRIM_WHEEL_LINE_HEIGHT;
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
