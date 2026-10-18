package client.ui.common;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;

using client.ui.ComponentExtension;

/**
    A row of tabs drawn as their captions, each followed by an optional count; the selected one is
    underlined in brass. `large` captions are heading-sized, the others body-sized.
**/
class UnderlineTabs extends HBox
{
    private final tabs:Array<HBox> = [];
    private final countLabels:Array<Label> = [];
    private final onSelected:Int->Void;

    /** Assigning it only renders the selection: `onSelected` is for the user's clicks **/
    public var selectedIndex(default, set):Int = -1;

    /** `captions` are locale bindings; `onSelected` gets the index of a tab clicked while not selected **/
    public function new(captions:Array<String>, large:Bool, onSelected:Int->Void)
    {
        super();
        this.onSelected = onSelected;
        percentWidth = 100;
        addClass(StyleClass.UNDERLINE_TABS);
        this.setClass(StyleClass.UNDERLINE_TABS_LARGE, large);

        for (i in 0...captions.length)
        {
            var tab:HBox = new HBox();
            tab.percentHeight = 100;
            tab.addClass(StyleClass.UNDERLINE_TAB);
            tab.trackHover();
            tab.registerEvent(MouseEvent.CLICK, _ -> {
                if (selectedIndex != i)
                {
                    selectedIndex = i;
                    onSelected(i);
                }
            });

            var captionLabel:Label = new Label();
            captionLabel.text = captions[i];
            captionLabel.addClass(StyleClass.UNDERLINE_TAB_CAPTION);
            captionLabel.verticalAlign = "center";
            tab.addComponent(captionLabel);

            var countLabel:Label = new Label();
            countLabel.addClass(StyleClass.UNDERLINE_TAB_COUNT);
            countLabel.verticalAlign = "center";
            countLabel.hidden = true;
            tab.addComponent(countLabel);

            tabs.push(tab);
            countLabels.push(countLabel);
            addComponent(tab);
        }
    }

    /** Shows `count` after tab `index`'s caption, or nothing for null **/
    public function setCount(index:Int, count:Null<Int>):Void
    {
        countLabels[index].hidden = count == null;
        if (count != null)
            countLabels[index].text = Std.string(count);
    }

    private function set_selectedIndex(value:Int):Int
    {
        selectedIndex = value;
        for (i in 0...tabs.length)
            tabs[i].setClass(StyleClass.UNDERLINE_TAB_SELECTED, i == value);
        return value;
    }
}
