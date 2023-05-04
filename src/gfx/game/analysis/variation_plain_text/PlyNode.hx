package gfx.game.analysis.variation_plain_text;

import net.shared.board.RawPly;
import haxe.ui.styles.Style;
import net.shared.variation.ReadOnlyVariation;
import net.shared.variation.VariationPath;
import haxe.ui.components.Link;

class PlyNode extends Link
{
    public var path(default, set):VariationPath;
    public var selected(get, set):Bool;

    private function set_path(v:VariationPath):VariationPath
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontItalic = !v.isMainLine();
        customStyle = newStyle;
        return path = v.copy();
    }

    private function get_selected():Bool
    {
        return customStyle.fontBold;
    }

    private function set_selected(v:Bool):Bool
    {
        var newStyle:Style = customStyle.clone();
        newStyle.fontBold = v;
        customStyle = newStyle;
        return v;
    }

    public function new(path:VariationPath, text:String, onNodeSelectRequest:VariationPath->Void, onNodeRemoveRequest:VariationPath->Void, defaultStyle:Style) 
    {
        super();
        this.text = text;
        
        verticalAlign = 'center';
        customStyle = defaultStyle;
        onClick = e -> {
            if (e.ctrlKey)
                onNodeRemoveRequest(this.path);
            else
                onNodeSelectRequest(this.path);
        }

        set_path(path);
    }
}