package client.ui.games;

import client.datatypes.games.ResultColumn;
import client.datatypes.games.SortLevel;
import client.formatters.ArchiveFormatters;
import client.logic.games.SortRules;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/**
    "Sorted by" and a chip per sort level: a click flips the level's direction, its cross removes it.
    "Then by" adds a level, offering the visible columns not sorted by yet.
**/
class SortChips extends HBox
{
    private static inline final POPUP_WIDTH:Float = 240;

    private var levels:Array<SortLevel> = [];
    private var visibleColumns:Array<ResultColumn> = [];

    /** The new levels, after a change by the user **/
    public var onChanged:Array<SortLevel>->Void = _ -> {};

    public function new()
    {
        super();
        addClass(StyleClass.GAMES_SORT_CHIPS);
    }

    public function render(levels:Array<SortLevel>, visibleColumns:Array<ResultColumn>):Void
    {
        this.levels = levels;
        this.visibleColumns = visibleColumns;
        removeAllComponents();

        addComponent(caption("intellector.games.sort.sorted_by"));
        for (i in 0...levels.length)
        {
            if (i > 0)
                addComponent(caption("intellector.games.sort.then"));
            addComponent(chip(i));
        }

        var addable:Array<ResultColumn> = SortRules.addable(levels, visibleColumns);
        if (addable.length > 0)
            addComponent(addLevelButton(addable));
    }

    private function caption(key:String):Label
    {
        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(key);
        label.addClass(StyleClass.GAMES_CAPTION);
        label.verticalAlign = "center";
        return label;
    }

    private function chip(index:Int):HBox
    {
        var level:SortLevel = levels[index];

        var chip:HBox = new HBox();
        chip.addClass(StyleClass.GAMES_SORT_CHIP);
        chip.verticalAlign = "center";
        chip.registerEvent(MouseEvent.CLICK, _ -> onChanged(SortRules.flip(levels, index)));

        var label:Label = new Label();
        LocaleManager.instance.registerComponent(label, "text", () -> '${ArchiveFormatters.columnName(level.column)} ${level.descending ? "↓" : "↑"}');
        label.addClass(StyleClass.GAMES_SORT_CHIP_TEXT);
        label.verticalAlign = "center";
        chip.addComponent(label);

        var cross:Box = new Box();
        cross.addClass(StyleClass.GAMES_SORT_CHIP_CROSS);
        cross.verticalAlign = "center";
        cross.registerEvent(MouseEvent.CLICK, event -> {
            event.cancel();
            onChanged(SortRules.remove(levels, index));
        });
        var crossIcon:Image = new Image();
        crossIcon.resource = Assets.gamesIcon("cross_accent");
        crossIcon.horizontalAlign = "center";
        crossIcon.verticalAlign = "center";
        cross.addComponent(crossIcon);
        chip.addComponent(cross);

        return chip;
    }

    private function addLevelButton(addable:Array<ResultColumn>):Box
    {
        var anchor:Box = new Box();
        anchor.verticalAlign = "center";

        var button:HBox = new HBox();
        button.addClass(StyleClass.GAMES_SORT_ADD);
        button.trackHover();
        anchor.addComponent(button);

        var icon:Image = new Image();
        icon.resource = Assets.gamesIcon("plus");
        icon.verticalAlign = "center";
        button.addComponent(icon);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding("intellector.games.sort.then_by");
        label.addClass(StyleClass.GAMES_SORT_ADD_TEXT);
        label.verticalAlign = "center";
        button.addComponent(label);

        var popup:AnchoredPopup = new AnchoredPopup(anchor, POPUP_WIDTH, Start);
        for (column in addable)
        {
            var option:HBox = new HBox();
            option.percentWidth = 100;
            option.addClass(StyleClass.FILTER_OPTION);
            option.trackHover();
            option.registerEvent(MouseEvent.CLICK, _ -> {
                popup.close();
                onChanged(SortRules.add(levels, column));
            });
            var optionLabel:Label = new Label();
            LocaleManager.instance.registerComponent(optionLabel, "text", () -> ArchiveFormatters.columnName(column));
            optionLabel.addClass(StyleClass.FILTER_OPTION_CAPTION);
            optionLabel.verticalAlign = "center";
            option.addComponent(optionLabel);
            popup.addComponent(option);
        }

        button.registerEvent(MouseEvent.CLICK, _ -> popup.toggle());
        return anchor;
    }
}
