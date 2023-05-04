package gfx.game.common.ply_history_view;

import haxe.ui.events.MouseEvent;
import haxe.ui.styles.Style;
import haxe.ui.core.ItemRenderer;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/move_cell_renderer.xml"))
class MoveCellRenderer extends ItemRenderer
{
    private var onMoveSelected:Null<Void->Void>;

    @:bind(label, MouseEvent.MOUSE_OVER)
    private function onHover(e) 
    {
        if (onMoveSelected == null)
            return;

        var newStyle:Style = label.customStyle.clone();
        newStyle.fontItalic = true;
        label.customStyle = newStyle;
    }

    @:bind(label, MouseEvent.MOUSE_OUT)
    private function onOut(e) 
    {
        var newStyle:Style = label.customStyle.clone();
        newStyle.fontItalic = false;
        label.customStyle = newStyle;
    }

    @:bind(label, MouseEvent.CLICK)
    private function onClicked(e) 
    {
        if (onMoveSelected != null)
            onMoveSelected();
    }

    private override function onDataChanged(data:Dynamic) 
    {
        super.onDataChanged(data);
        var columnData = Reflect.field(data, id);
        if (columnData != null) 
        {
            onMoveSelected = columnData.onMoveSelected;
            label.text = columnData.plyStr;

            var newStyle:Style = label.customStyle.clone();

            if (columnData.selected)
            {
                newStyle.fontBold = true;
                newStyle.color = 0x000000;
                newStyle.fontSize = 14;
            }
            else
            {
                newStyle.fontBold = false;
                newStyle.color = 0x666666;
                newStyle.fontSize = 12;
            }

            label.customStyle = newStyle;
        }
    }
}