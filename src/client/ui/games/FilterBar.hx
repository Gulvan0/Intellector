package client.ui.games;

import client.datatypes.games.SavedFilter;
import client.datatypes.games.SavedFilterSummary;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;

using client.ui.ComponentExtension;

/** What the "Open filter" dropdown shows **/
enum OpenListState
{
    Loading;
    Failed;
    Filters(filters:Array<SavedFilterSummary>);
}

/**
    The row above the formula box: the name and author of the saved filter the last search ran, and
    the Share, Save, Delete (the user's own filter only) and Open buttons. Open drops down the
    user's filters, filled by `setOpenList`. Narrow, the buttons go under the name, two by two.
**/
class FilterBar extends VBox
{
    private static inline final OPEN_POPUP_WIDTH:Float = 280;
    private static inline final OPEN_LIST_MAX_HEIGHT:Float = 305;
    private static inline final OPTION_HEIGHT:Float = 37;
    private static inline final LIST_PADDING:Float = 16;

    private final topRow:HBox;
    private final title:HBox;
    private final buttonRow:HBox;
    private final buttonGrid:Grid;
    /** Share, Save, Delete, then Open's holder **/
    private final buttons:Array<Box> = [];
    private final icons:Array<Image> = [];
    private final nameLabel:Label;
    private final authorLabel:Label;
    private final deleteButton:Box;
    private final openHolder:Box;
    private final openChevron:Image;
    private final openPopup:AnchoredPopup;
    /** Whether a saved filter is named (`hidden` would also tell the hidden row's state) **/
    private var titleShown:Bool = false;

    public var onShare:Void->Void = () -> {};
    public var onSave:Void->Void = () -> {};
    public var onDelete:Void->Void = () -> {};
    /** The dropdown opened: the list is to be requested and given to `setOpenList`; false to keep it closed **/
    public var onOpenPressed:Void->Bool = () -> true;
    public var onFilterPicked:SavedFilterSummary->Void = _ -> {};

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAMES_FILTER_BAR);

        topRow = new HBox();
        topRow.percentWidth = 100;
        topRow.addClass(StyleClass.GAMES_FILTER_TOP_ROW);
        addComponent(topRow);

        title = new HBox();
        title.addClass(StyleClass.GAMES_FILTER_TITLE);
        title.verticalAlign = "center";
        nameLabel = new Label();
        nameLabel.addClass(StyleClass.GAMES_FILTER_NAME);
        title.addComponent(nameLabel);
        authorLabel = new Label();
        authorLabel.addClass(StyleClass.GAMES_FILTER_AUTHOR);
        title.addComponent(authorLabel);
        topRow.addComponent(title);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        topRow.addComponent(spacer);

        buttonRow = new HBox();
        buttonRow.addClass(StyleClass.GAMES_FILTER_BUTTONS);
        buttonRow.verticalAlign = "center";
        topRow.addComponent(buttonRow);

        buttonGrid = new Grid();
        buttonGrid.columns = 2;
        buttonGrid.percentWidth = 100;
        buttonGrid.addClass(StyleClass.GAMES_FILTER_BUTTONS);
        buttonGrid.hidden = true;
        addComponent(buttonGrid);

        buttons.push(button("share", "intellector.games.filter.share", () -> onShare()));
        buttons.push(button("save", "intellector.games.filter.save", () -> onSave()));
        deleteButton = button("delete", "intellector.games.filter.delete", () -> onDelete());
        deleteButton.hidden = true;
        buttons.push(deleteButton);

        openHolder = new Box();
        var openButton:Box = button("open", "intellector.games.filter.open", toggleOpenList);
        openChevron = new Image();
        openChevron.resource = Assets.gamesIcon("chevron_down");
        openChevron.verticalAlign = "center";
        openButton.childComponents[0].addComponent(openChevron);
        openHolder.addComponent(openButton);
        buttons.push(openHolder);

        openPopup = new AnchoredPopup(openHolder, OPEN_POPUP_WIDTH, End);
        openPopup.onClosed = () -> openChevron.resource = Assets.gamesIcon("chevron_down");
        for (button in buttons)
            buttonRow.addComponent(button);
        setFilter(null, false);
    }

    /** Narrow: the buttons fill a grid of two columns under the name, without their icons **/
    public function setNarrow(narrow:Bool):Void
    {
        var target:Component = narrow ? buttonGrid : buttonRow;
        for (button in buttons)
        {
            if (button.parentComponent != target)
            {
                if (button.parentComponent != null)
                    button.parentComponent.removeComponent(button, false);
                target.addComponent(button);
            }
            button.setFillsWidth(narrow);
            if (button == openHolder)
                openHolder.childComponents[0].setFillsWidth(narrow);
        }
        for (icon in icons)
            icon.hidden = narrow;
        buttonGrid.hidden = !narrow;
        refreshTopRow();
    }

    private function refreshTopRow():Void
    {
        topRow.hidden = buttonRow.childComponents.length == 0 && !titleShown;
    }

    /** `filter`: the saved filter the last search ran, if any; `own`: whether it is the user's **/
    public function setFilter(filter:Null<SavedFilter>, own:Bool):Void
    {
        titleShown = filter != null;
        title.hidden = !titleShown;
        deleteButton.hidden = filter == null || !own;
        refreshTopRow();
        if (filter == null)
            return;

        if (filter.key != null)
            nameLabel.text = LocaleUtils.localeBinding('intellector.games.filter.${filter.key}');
        else
            nameLabel.text = filter.name;

        var authorLogin:Null<String> = filter.authorLogin;
        authorLabel.hidden = authorLogin == null;
        if (own)
            authorLabel.text = LocaleUtils.localeBinding("intellector.games.filter.by_you");
        else if (authorLogin != null)
        {
            var author:String = filter.authorNickname ?? authorLogin;
            LocaleManager.instance.registerComponent(authorLabel, "text", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.filter.by"), author));
        }
    }

    /** Fills the "Open filter" dropdown, if open **/
    public function setOpenList(state:OpenListState):Void
    {
        if (!openPopup.isOpen)
            return;

        openPopup.removeAllComponents();
        switch state
        {
            case Loading:
                openPopup.addComponent(stateText("intellector.games.open.loading"));
            case Failed:
                openPopup.addComponent(stateText("intellector.games.open.failed"));
            case Filters([]):
                openPopup.addComponent(stateText("intellector.games.open.empty"));
            case Filters(filters):
                var list:VBox = new VBox();
                list.addClass(StyleClass.GAMES_OPEN_LIST);
                for (filter in filters)
                    list.addComponent(option(filter));
                var scroller:ScrollArea = new ScrollArea(list);
                scroller.height = Math.min(OPEN_LIST_MAX_HEIGHT, LIST_PADDING + OPTION_HEIGHT * filters.length);
                openPopup.addComponent(scroller);
        }
    }

    public function closeOpenList():Void
    {
        openPopup.close();
    }

    private function toggleOpenList():Void
    {
        if (openPopup.isOpen)
        {
            openPopup.close();
            return;
        }
        if (!onOpenPressed())
            return;
        openPopup.open();
        openChevron.resource = Assets.gamesIcon("chevron_up");
        setOpenList(Loading);
    }

    private function option(filter:SavedFilterSummary):HBox
    {
        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.addClass(StyleClass.FILTER_OPTION);
        row.trackHover();
        row.registerEvent(MouseEvent.CLICK, _ -> {
            openPopup.close();
            onFilterPicked(filter);
        });
        var label:Label = new Label();
        label.percentWidth = 100;
        label.text = filter.name;
        label.addClass(StyleClass.FILTER_OPTION_CAPTION);
        label.verticalAlign = "center";
        row.addComponent(label);
        return row;
    }

    private static function stateText(key:String):Box
    {
        var box:Box = new Box();
        box.percentWidth = 100;
        box.addClass(StyleClass.GAMES_OPEN_STATE);
        var label:Label = new Label();
        label.percentWidth = 100;
        label.text = LocaleUtils.localeBinding(key);
        label.addClass(StyleClass.GAMES_RESULTS_STATE_TEXT);
        label.verticalAlign = "center";
        box.addComponent(label);
        return box;
    }

    /** A button whose content, its icon and caption, is centred in it **/
    private function button(icon:String, textKey:String, onClick:Void->Void):Box
    {
        var button:Box = new Box();
        button.addClass(StyleClass.GAMES_BUTTON);
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> onClick());

        var content:HBox = new HBox();
        content.addClass(StyleClass.GAMES_BUTTON_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        button.addComponent(content);

        var image:Image = new Image();
        image.resource = Assets.gamesIcon(icon);
        image.verticalAlign = "center";
        content.addComponent(image);
        icons.push(image);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding(textKey);
        label.addClass(StyleClass.GAMES_BUTTON_TEXT);
        label.verticalAlign = "center";
        content.addComponent(label);
        return button;
    }
}
