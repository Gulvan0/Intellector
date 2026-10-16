package client.ui.analysis.variations;

import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;

/** The browser's own scroller around `content`: vertical, or both ways when `horizontal` **/
class NativeScroller extends ScrollView
{
    private final horizontal:Bool;

    public function new(content:Component, horizontal:Bool)
    {
        super();
        this.horizontal = horizontal;
        percentWidth = 100;
        percentHeight = 100;
        scrollMode = NATIVE;
        if (!horizontal)
            percentContentWidth = 100;
        addClass(StyleClass.VARIATION_SCROLLER);
        addComponent(content);
    }

    // HaxeUI applies its own overflow to a native scroller when it becomes ready
    private override function onReady():Void
    {
        super.onReady();
        element.style.overflowX = horizontal ? "auto" : "hidden";
        element.style.overflowY = "auto";
        (cast element.style : Dynamic).overscrollBehavior = "contain";
    }
}
