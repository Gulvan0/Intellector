package gfx.analysis;

import openfl.text.TextFieldAutoSize;
import openfl.text.TextFieldType;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.geom.Point;
import haxe.ui.components.Link;

class Node extends Link
{
    public var code:String;
    public var textSize(default, null):{w:Float, h:Float};

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

        textSize = measureTextSize(text);
        width = textSize.w;
        height = textSize.h;
    }

    private function measureTextSize(text:String):{w:Float, h:Float} {
        var _tempField = new TextField();
        _tempField.type = TextFieldType.DYNAMIC;
        _tempField.selectable = false;
        _tempField.mouseEnabled = false;
        _tempField.autoSize = TextFieldAutoSize.LEFT;
        
        _tempField.defaultTextFormat = new TextFormat("_sans", 13, null, true, false, true);
        _tempField.text = text;
        return {w: _tempField.textWidth + 4, h: _tempField.textHeight + 2};
    }
}