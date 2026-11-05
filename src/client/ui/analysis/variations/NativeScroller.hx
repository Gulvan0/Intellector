package client.ui.analysis.variations;

import haxe.ui.containers.ScrollView;
import haxe.ui.core.Component;
import haxefolio.structure.SidewaysScroll;
import js.Browser;
import js.html.StyleElement;

/** The browser's own scroller around `content`: vertical, or both ways when `horizontal` **/
class NativeScroller extends ScrollView
{
    private static inline final SIDEWAYS_CLASS:String = "intellector-sideways-scroller";

    private static var styleInjected:Bool = false;

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
        if (horizontal)
        {
            injectStyleOnce();
            element.classList.add(SIDEWAYS_CLASS);
            SidewaysScroll.attach(element, 0);
        }
    }

    // the enclosing scroll area lets touch pan vertically only, on its descendants too; this scroller needs both ways
    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;
        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '#haxeui-container .haxeui-component.$SIDEWAYS_CLASS, #haxeui-container .haxeui-component.$SIDEWAYS_CLASS .haxeui-component { touch-action: pan-x pan-y; }';
        Browser.document.head.appendChild(style);
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
