package client.ui.common;

import haxe.ui.components.Label;
import haxe.ui.locale.LocaleManager;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.CanvasRenderingContext2D;

/**
    Text made of parts joined by ` · `. When the label is too narrow for it, the parts are broken
    onto separate lines and the separator is dropped at each break.
**/
class FoldingText
{
    private static inline final SEPARATOR:String = " · ";

    private static var measuringContext:Null<CanvasRenderingContext2D> = null;

    /** Keeps `label`'s text as `resolveText()`, folded to the label's width; `resolveText` is re-run on locale changes and resizes **/
    public static function attach(label:Label, resolveText:Void->String):Void
    {
        var labelWidth:Float = 0;
        LocaleManager.instance.registerComponent(label, "text", () -> fold(label, resolveText(), labelWidth));
        WidthObserver.observe(label, width -> {
            labelWidth = width;
            LocaleManager.instance.refreshFor(label);
        });
    }

    private static function fold(label:Label, text:String, width:Float):String
    {
        if (width <= 0 || measure(label, text) <= width)
            return text;

        var lines:Array<String> = [];
        var current:String = "";
        for (part in text.split(SEPARATOR))
        {
            if (current.length == 0)
                current = part;
            else if (measure(label, current + SEPARATOR + part) <= width)
                current += SEPARATOR + part;
            else
            {
                lines.push(current);
                current = part;
            }
        }
        lines.push(current);
        return lines.join("\n");
    }

    private static function measure(label:Label, text:String):Float
    {
        if (measuringContext == null)
            measuringContext = Browser.document.createCanvasElement().getContext2d();

        var style:CSSStyleDeclaration = Browser.window.getComputedStyle(label.getTextDisplay().element);
        measuringContext.font = '${style.fontStyle} ${style.fontWeight} ${style.fontSize} ${style.fontFamily}';
        return Math.ceil(measuringContext.measureText(text).width);
    }
}
