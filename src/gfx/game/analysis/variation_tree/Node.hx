package gfx.game.analysis.variation_tree;

import net.shared.variation.VariationPath;
import haxe.ui.backend.html5.text.TextMeasurer;
import haxe.ui.geom.Point;
import haxe.ui.components.Link;

class Node extends Link
{
    public var path:VariationPath;
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

    public function new(scale:Float, path:VariationPath, text:String, selected:Bool, onSelectRequested:VariationPath->Void, onRemovalRequested:VariationPath->Void)
    {
        super();
        this.path = path;
        this.text = text;
        this.onClick = (e) -> {
            if (e.ctrlKey)
                onRemovalRequested(this.path);
            else
                onSelectRequested(this.path);
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