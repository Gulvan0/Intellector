package client.ui.games;

import client.datatypes.games.ResultColumn;
import client.formatters.ArchiveFormatters;
import client.logic.games.ResultColumns;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    The "Columns" button and its checklist of the result columns, which the XLSX export uses as well.
    The last visible column can't be unchecked.
**/
class ColumnsDropdown extends Box
{
    private static inline final POPUP_WIDTH:Float = 280;

    private final popup:AnchoredPopup;
    private final chevron:Image;
    private final boxes:Map<ResultColumn, Box> = [];

    private var visible:Array<ResultColumn> = [];

    /** The new visible columns, in the table's order, after a change by the user **/
    public var onChanged:Array<ResultColumn>->Void = _ -> {};

    public function new()
    {
        super();

        var button:HBox = new HBox();
        button.addClass(StyleClass.GAMES_BUTTON);
        button.trackHover();
        addComponent(button);

        var icon:Image = new Image();
        icon.resource = Assets.gamesIcon("columns");
        icon.verticalAlign = "center";
        button.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.games.columns.button");
        label.addClass(StyleClass.GAMES_BUTTON_TEXT);
        label.verticalAlign = "center";
        button.addComponent(label);

        chevron = new Image();
        chevron.resource = Assets.gamesIcon("chevron_down");
        chevron.verticalAlign = "center";
        button.addComponent(chevron);

        popup = new AnchoredPopup(this, POPUP_WIDTH, End);
        popup.onClosed = () -> chevron.resource = Assets.gamesIcon("chevron_down");

        var hint:Label = new Label();
        hint.percentWidth = 100;
        hint.text = LocaleUtils.localeBinding("intellector.games.columns.hint");
        hint.addClass(StyleClass.FILTER_POPUP_HINT);
        popup.addComponent(hint);

        for (column in ResultColumns.ALL)
            popup.addComponent(createOption(column));

        var footer:HBox = new HBox();
        footer.percentWidth = 100;
        footer.addClass(StyleClass.GAMES_COLUMNS_FOOTER);
        var reset:HBox = new HBox();
        reset.addClass(StyleClass.GAMES_SMALL_BUTTON);
        reset.horizontalAlign = "right";
        reset.trackHover();
        reset.registerEvent(MouseEvent.CLICK, _ -> change(ResultColumns.DEFAULT_VISIBLE.copy()));
        var resetLabel:Label = new Label();
        resetLabel.text = LocaleUtils.localeBinding("intellector.games.columns.reset");
        resetLabel.addClass(StyleClass.GAMES_BUTTON_TEXT);
        resetLabel.verticalAlign = "center";
        reset.addComponent(resetLabel);
        footer.addComponent(reset);
        popup.addComponent(footer);

        button.registerEvent(MouseEvent.CLICK, _ -> {
            popup.toggle();
            chevron.resource = Assets.gamesIcon(popup.isOpen ? "chevron_up" : "chevron_down");
        });
    }

    public function setVisible(columns:Array<ResultColumn>):Void
    {
        visible = columns.copy();
        for (column => box in boxes)
            box.setClass(StyleClass.FILTER_BOX_ON, visible.contains(column));
    }

    private function createOption(column:ResultColumn):HBox
    {
        var option:HBox = new HBox();
        option.percentWidth = 100;
        option.addClass(StyleClass.FILTER_OPTION);
        option.trackHover();
        option.registerEvent(MouseEvent.CLICK, _ -> toggle(column));

        var box:Box = new Box();
        box.addClass(StyleClass.FILTER_CHECKBOX);
        box.verticalAlign = "center";
        var check:Image = new Image();
        check.resource = Assets.controlIcon("check");
        check.width = 10;
        check.height = 10;
        check.horizontalAlign = "center";
        check.verticalAlign = "center";
        box.addComponent(check);
        option.addComponent(box);
        boxes.set(column, box);

        var caption:Label = new Label();
        caption.percentWidth = 100;
        LocaleManager.instance.registerComponent(caption, "text", () -> ArchiveFormatters.columnName(column));
        caption.addClass(StyleClass.FILTER_OPTION_CAPTION);
        caption.verticalAlign = "center";
        option.addComponent(caption);

        return option;
    }

    private function toggle(column:ResultColumn):Void
    {
        if (!visible.contains(column))
            change(ResultColumns.ordered(visible.concat([column])));
        else if (visible.length > 1)
            change(visible.filter(other -> other != column));
    }

    private function change(columns:Array<ResultColumn>):Void
    {
        setVisible(columns);
        onChanged(columns.copy());
    }
}
