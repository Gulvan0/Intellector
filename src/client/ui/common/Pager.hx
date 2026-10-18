package client.ui.common;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.KeyboardEvent;
import haxefolio.LocaleUtils;

using StringTools;
using client.ui.ComponentExtension;

/**
    Numbered pages: the range shown, previous / next, and a field for jumping to a page, which
    applies on Enter. While its text isn't the current page, a line under it says to press Enter,
    or what a page number has to be.
**/
class Pager extends HBox
{
    private static inline final ENTER_KEY_CODE:Int = 13;
    private static inline final ESCAPE_KEY_CODE:Int = 27;

    private final onPage:Int->Void;

    private final rangeLabel:Label;
    private final previousButton:Button;
    private final pageField:TextField;
    private final messageLabel:Label;
    private final ofLabel:Label;
    private final nextButton:Button;

    private var page:Int = 1;
    private var pageCount:Int = 1;

    /** `onPage` gets the page the user asked for, one of `1...pageCount` **/
    public function new(onPage:Int->Void)
    {
        super();
        this.onPage = onPage;
        percentWidth = 100;
        addClass(StyleClass.PAGER);

        rangeLabel = new Label();
        rangeLabel.percentWidth = 100;
        rangeLabel.addClass(StyleClass.PAGER_TEXT);
        rangeLabel.addClass(StyleClass.PAGER_RANGE);
        addComponent(rangeLabel);

        var controls:HBox = new HBox();
        controls.addClass(StyleClass.PAGER_CONTROLS);
        addComponent(controls);

        previousButton = createNavigationButton("page_previous", "intellector.common.pager.previous", () -> goTo(page - 1));
        controls.addComponent(previousButton);

        var pageLabel:Label = new Label();
        pageLabel.text = LocaleUtils.localeBinding("intellector.common.pager.page");
        pageLabel.addClass(StyleClass.PAGER_TEXT);
        controls.addComponent(pageLabel);

        var fieldColumn:VBox = new VBox();
        fieldColumn.addClass(StyleClass.PAGER_FIELD_COLUMN);
        controls.addComponent(fieldColumn);

        pageField = new TextField();
        pageField.addClass(StyleClass.PAGER_FIELD);
        pageField.onChange = _ -> refreshMessage();
        pageField.registerEvent(KeyboardEvent.KEY_DOWN, onFieldKeyDown);
        fieldColumn.addComponent(pageField);

        messageLabel = new Label();
        messageLabel.addClass(StyleClass.PAGER_MESSAGE);
        messageLabel.horizontalAlign = "center";
        fieldColumn.addComponent(messageLabel);

        ofLabel = new Label();
        ofLabel.addClass(StyleClass.PAGER_TEXT);
        controls.addComponent(ofLabel);

        nextButton = createNavigationButton("page_next", "intellector.common.pager.next", () -> goTo(page + 1));
        controls.addComponent(nextButton);

        setState(1, 1, 0, 0, 0);
    }

    /** Shows `page` of `pageCount`, holding items `first`-`last` (1-based) of `total` **/
    public function setState(page:Int, pageCount:Int, first:Int, last:Int, total:Int):Void
    {
        this.page = page;
        this.pageCount = pageCount;

        rangeLabel.text = total > 0 ? LocaleUtils.localeBinding("intellector.common.pager.range", '$first', '$last', '$total') : "";
        ofLabel.text = LocaleUtils.localeBinding("intellector.common.pager.of", '$pageCount');
        previousButton.disabled = page <= 1;
        nextButton.disabled = page >= pageCount;
        pageField.text = Std.string(page);
        refreshMessage();
    }

    private function createNavigationButton(iconName:String, tooltipKey:String, onClick:Void->Void):Button
    {
        var button:Button = new Button();
        button.icon = Assets.controlIcon(iconName);
        button.tooltip = LocaleUtils.localeBinding(tooltipKey);
        button.addClass(StyleClass.PAGER_BUTTON);
        button.onClick = _ -> onClick();
        return button;
    }

    private function goTo(target:Int):Void
    {
        if (target >= 1 && target <= pageCount && target != page)
            onPage(target);
    }

    private function onFieldKeyDown(event:KeyboardEvent):Void
    {
        if (event.keyCode == ENTER_KEY_CODE)
        {
            var target:Null<Int> = typedPage();
            if (target != null)
                goTo(target);
        }
        else if (event.keyCode == ESCAPE_KEY_CODE)
        {
            pageField.text = Std.string(page);
            refreshMessage();
        }
    }

    /** The typed page number if it's a valid one, else null **/
    private function typedPage():Null<Int>
    {
        var text:String = (pageField.text ?? "").trim();
        var value:Null<Int> = ~/^[0-9]+$/.match(text) ? Std.parseInt(text) : null;
        return value != null && value >= 1 && value <= pageCount ? value : null;
    }

    private function refreshMessage():Void
    {
        var unchanged:Bool = (pageField.text ?? "").trim() == Std.string(page);
        var invalid:Bool = !unchanged && typedPage() == null;

        pageField.setClass(StyleClass.PAGER_FIELD_INVALID, invalid);
        messageLabel.setClass(StyleClass.PAGER_MESSAGE_INVALID, invalid);
        if (unchanged)
            messageLabel.text = "";
        else if (invalid)
            messageLabel.text = LocaleUtils.localeBinding("intellector.common.pager.must_be", '$pageCount');
        else
            messageLabel.text = LocaleUtils.localeBinding("intellector.common.pager.press_enter");
    }
}
