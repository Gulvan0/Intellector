package gfx.common;

import haxe.ui.core.ItemRenderer;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/move_cell_renderer.xml"))
class MoveCellRenderer extends ItemRenderer
{
    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        var columnData = Reflect.field(data, id);
        if (columnData != null) 
        {
            label.text = columnData.plyStr;
            if (columnData.selected)
                label.customStyle = {fontBold: true, color: 0x000000, fontSize: 14};
            else
                label.customStyle = {fontBold: false, color: 0x666666, fontSize: 12};
        }
    }
}