package gfx.analysis;

import openfl.geom.Point;
import struct.Variant.VariantPath;
import haxe.ui.components.Link;

class Node extends Link
{
    public var code:String;
    public var textWidth(default, null):Float;

    public function inputPos():Point
    {
        return new Point(x + width/2, y);
    }

    public function outputPos():Point
    {
        return new Point(x + width/2, y + height + 5);
    }

    public function select()
    {
        this.customStyle = {fontBold: true, textAlign: 'center'};
    }

    public function deselect()
    {
        this.customStyle = {fontBold: false, textAlign: 'center'};
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

        validateNow();
        textWidth = width;

        if (selected)
            select();
    }
}