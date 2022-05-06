package gfx.analysis;

import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextField;
import openfl.text.TextFormat;
import haxe.ui.components.Label;
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
        return new Point(x + width/2, y + height + 2);
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

        textWidth = measureTextWidthArg(text);
        width = textWidth;
    }

    private function measureTextWidthArg(text:String):Float {
        var _tempField = new TextField();
        _tempField.type = TextFieldType.DYNAMIC;
        _tempField.selectable = false;
        _tempField.mouseEnabled = false;
        _tempField.autoSize = TextFieldAutoSize.LEFT;
        
        _tempField.defaultTextFormat = new TextFormat("_sans", 13, null, true, false, true);
        _tempField.text = text;
        return _tempField.textWidth + 4;
    }
}