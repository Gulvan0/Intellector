package client.ui.common;

import haxe.ui.Toolkit;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;

/**
    Makes a wrapping (continuous) row of parts separated by `·`. A part that doesn't fit beside the
    previous one together with its separator moves onto a new line without it, even if it would
    fit without it, so no line starts or ends with a separator.

    The row re-evaluates itself when it or any part is resized, and when a part is shown or hidden
    through `setPartHidden`.
**/
class SeparatedFlow
{
    private final flow:Component;
    private final groups:Array<HBox> = [];
    private final separators:Array<Label> = [];
    private final lineBreaks:Array<Box> = [];

    /**
        Takes over `flow`, which must be a wrapping row holding only `parts`, in order. Each part
        is put into a group of `groupClass` with its separator, styled `separatorClass`.
    **/
    public function new(flow:Component, parts:Array<Component>, groupClass:String, separatorClass:String)
    {
        this.flow = flow;

        for (part in parts)
        {
            part.parentComponent.removeComponent(part, false);

            var separator:Label = new Label();
            separator.text = "·";
            separator.addClass(separatorClass);
            separator.verticalAlign = "center";

            var group:HBox = new HBox();
            group.addClass(groupClass);
            group.addComponent(separator);
            group.addComponent(part);

            var lineBreak:Box = new Box();
            lineBreak.percentWidth = 100;
            lineBreak.height = 0;
            lineBreak.hidden = true;

            flow.addComponent(lineBreak);
            flow.addComponent(group);
            groups.push(group);
            separators.push(separator);
            lineBreaks.push(lineBreak);
            WidthObserver.observe(part, _ -> update());
        }

        WidthObserver.observe(flow, _ -> update());
    }

    /** The group around `part`, for sizing the part's slot in the row **/
    public function groupOf(part:Component):HBox
    {
        return cast part.parentComponent;
    }

    public function setPartHidden(part:Component, hidden:Bool):Void
    {
        groupOf(part).hidden = hidden;
        update();
    }

    private function update():Void
    {
        Toolkit.callLater(arrange); // so that the row has its final width
    }

    private function arrange():Void
    {
        if (!flow.isReady || flow.width <= 0)
            return;

        var shown:Array<Int> = [for (i in 0...groups.length) if (!groups[i].hidden) i];
        for (i in 0...groups.length)
        {
            separators[i].hidden = shown.length == 0 || i == shown[0];
            lineBreaks[i].hidden = true;
        }
        flow.validateNow();

        var changed:Bool = true;
        while (changed)
        {
            changed = false;
            for (k in 1...shown.length)
            {
                var i:Int = shown[k];
                if (!separators[i].hidden && groups[i].top > groups[shown[k - 1]].top + 1)
                {
                    separators[i].hidden = true;
                    flow.validateNow();
                    if (groups[i].top <= groups[shown[k - 1]].top + 1) // fits without the separator, so it has to be forced down
                    {
                        var gap:Float = flow.style != null && flow.style.verticalSpacing != null ? flow.style.verticalSpacing : 0.0;
                        lineBreaks[i].marginTop = -gap; // the row it makes shouldn't widen the gap between lines
                        lineBreaks[i].hidden = false;
                        flow.validateNow();
                    }
                    changed = true;
                }
            }
        }
    }
}
