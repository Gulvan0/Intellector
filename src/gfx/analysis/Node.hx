package gfx.analysis;

import haxe.ui.backend.html5.text.TextMeasurer;
import haxe.ui.geom.Point;
import haxe.ui.components.Link;

class Node extends Link
{
    public var code:String;
    public var textSize(default, null):{width:Float, height:Float};

    public function inputPos():Point
    {
        return new Point(left + width/2, top);
    }

    public function outputPos():Point
    {
        return new Point(left + width/2, top + height + 2);
    }

    public function select()
    {
        this.customStyle = {fontBold: true, textAlign: 'center'/*, backgroundOpacity: 0.5, backgroundColor: 0x00FF00*/};
    }

    public function deselect()
    {
        this.customStyle = {fontBold: false, textAlign: 'center'/*, backgroundOpacity: 0.5, backgroundColor: 0x00FF00*/};
    }

    public function new(code:String, text:String, selected:Bool, onBranchSelect:(code:String)->Void, onBranchRemove:(code:String)->Void)
    {
        super();
        this.code = code;
        this.text = text;
        this.onClick = (e) -> {
            if (e.ctrlKey)
                onBranchRemove(this.code);
            else
                onBranchSelect(this.code);
        };

        if (selected)
            select();
        else
            deselect();

        textSize = TextMeasurer.instance.measureText({text: text, isHtml: false, fontSize: style.fontSize == null? null : Std.string(style.fontSize), fontFamily: style.fontName});
    }
}