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
        var newStyle = this.customStyle.clone();
        newStyle.fontBold = true;
        this.customStyle = newStyle;
    }

    public function deselect()
    {
        var newStyle = this.customStyle.clone();
        newStyle.fontBold = false;
        this.customStyle = newStyle;
    }

    public function new(scale:Float, code:String, text:String, selected:Bool, onBranchSelect:(code:String)->Void, onBranchRemove:(code:String)->Void)
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

        this.customStyle = {
            textAlign: 'center', 
            fontSize: 13 * scale
        };

        if (selected)
            select();
        else
            deselect();

        textSize = {width: 12 * text.length * scale, height: 20 * scale};
        width = textSize.width;
        height = textSize.height;
    }
}