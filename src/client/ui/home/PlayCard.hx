package client.ui.home;

import client.datatypes.changelog.ChangelogEntry;
import client.datatypes.timecontrol.FischerTimeControl;
import client.formatters.TimeControlFormatters;
import client.ui.common.TimeControlKindIcon;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;

using client.ui.ComponentExtension;

/**
    Starting a game: Create challenge, the quick-start time controls (each opens the same dialog
    with that time control set), and, quietest at the bottom, a link to the changelog reading the
    latest entry's title.
**/
class PlayCard extends VBox
{
    private static final PRESETS:Array<FischerTimeControl> = [
        new FischerTimeControl(60, 0),
        new FischerTimeControl(3 * 60, 2),
        new FischerTimeControl(5 * 60, 3),
        new FischerTimeControl(10 * 60, 5),
        new FischerTimeControl(15 * 60, 10),
        new FischerTimeControl(60 * 60, 0)
    ];

    private static inline final WIDE_HEIGHT:Float = 400;
    private static inline final NARROW_HEIGHT:Float = 430;
    private static inline final WIDE_COLUMNS:Int = 3;
    private static inline final NARROW_COLUMNS:Int = 2;

    private final onPreset:FischerTimeControl->Void;

    private final createButton:Button;
    private final presetGrid:VBox;
    private final changelogLink:HBox;
    private final changelogCaption:Label;

    private var narrow:Null<Bool> = null;

    /** `latestChange` titles the changelog link; null leaves the link without a title **/
    public function new(latestChange:Null<ChangelogEntry>, onCreate:Void->Void, onPreset:FischerTimeControl->Void)
    {
        super();
        this.onPreset = onPreset;
        addClass(StyleClass.HOME_CARD);
        addClass(StyleClass.HOME_PLAY_CARD);

        var titleLabel:Label = new Label();
        titleLabel.text = LocaleUtils.localeBinding("intellector.home.play.title");
        titleLabel.addClass(StyleClass.HOME_CARD_TITLE);
        addComponent(titleLabel);

        createButton = new Button();
        createButton.text = LocaleUtils.localeBinding("intellector.home.play.create");
        createButton.icon = Assets.homeIcon("plus");
        createButton.percentWidth = 100;
        createButton.addClass(StyleClass.GAME_BUTTON);
        createButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        createButton.addClass(StyleClass.HOME_CREATE_BUTTON);
        createButton.onClick = _ -> onCreate();
        addComponent(createButton);

        var quickStartLabel:Label = new Label();
        quickStartLabel.text = LocaleUtils.localeBinding("intellector.home.play.quick_start");
        quickStartLabel.addClass(StyleClass.HOME_QUICK_START_LABEL);
        addComponent(quickStartLabel);

        presetGrid = new VBox();
        presetGrid.percentWidth = 100;
        presetGrid.addClass(StyleClass.HOME_PRESET_GRID);
        addComponent(presetGrid);

        var hintLabel:Label = new Label();
        hintLabel.text = LocaleUtils.localeBinding("intellector.home.play.preset_hint");
        hintLabel.percentWidth = 100;
        hintLabel.addClass(StyleClass.HOME_PRESET_HINT);
        addComponent(hintLabel);

        var spacer:Box = new Box();
        spacer.percentHeight = 100;
        addComponent(spacer);

        changelogLink = new HBox();
        changelogLink.percentWidth = 100;
        changelogLink.addClass(StyleClass.HOME_CHANGELOG_LINK);
        changelogLink.trackHover();
        PageLink.attach(changelogLink, "changelog");
        addComponent(changelogLink);

        var changelogText:VBox = new VBox();
        changelogText.percentWidth = 100;
        changelogText.addClass(StyleClass.HOME_CHANGELOG_TEXT);
        changelogText.verticalAlign = "center";
        changelogLink.addComponent(changelogText);

        var whatsNewLabel:Label = new Label();
        whatsNewLabel.text = LocaleUtils.localeBinding("intellector.home.play.whats_new");
        whatsNewLabel.addClass(StyleClass.HOME_CHANGELOG_KICKER);
        changelogText.addComponent(whatsNewLabel);

        var titleOfChange:Label = new Label();
        titleOfChange.percentWidth = 100;
        titleOfChange.addClass(StyleClass.HOME_CHANGELOG_TITLE);
        if (latestChange != null)
            LocaleManager.instance.registerComponent(titleOfChange, "text", () -> latestChange.title(LocaleManager.instance.language));
        changelogText.addComponent(titleOfChange);

        changelogCaption = new Label();
        changelogCaption.text = LocaleUtils.localeBinding("intellector.home.play.changelog");
        changelogCaption.addClass(StyleClass.HOME_CHANGELOG_CAPTION);
        changelogCaption.verticalAlign = "center";
        changelogLink.addComponent(changelogCaption);

        var chevron:Image = new Image();
        chevron.resource = Assets.controlIcon("page_next");
        chevron.width = 14;
        chevron.height = 14;
        chevron.verticalAlign = "center";
        changelogLink.addComponent(chevron);

        setNarrow(false);
    }

    public function setNarrow(narrow:Bool):Void
    {
        if (narrow == this.narrow)
            return;
        this.narrow = narrow;

        height = narrow ? NARROW_HEIGHT : WIDE_HEIGHT;
        for (part in [this, createButton, changelogLink])
            part.setClass(StyleClass.HOME_NARROW, narrow);
        changelogCaption.hidden = narrow;

        presetGrid.removeAllComponents();

        var columns:Int = narrow ? NARROW_COLUMNS : WIDE_COLUMNS;
        var row:Null<HBox> = null;
        for (i in 0...PRESETS.length)
        {
            if (i % columns == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.HOME_PRESET_ROW);
                presetGrid.addComponent(row);
            }
            row.addComponent(createPresetButton(PRESETS[i], narrow));
        }
    }

    /** Wide: the time control over the kind's name; narrow: the two side by side **/
    private function createPresetButton(timeControl:FischerTimeControl, narrow:Bool):Box
    {
        var button:Box = new Box();
        button.percentWidth = 100;
        button.addClass(StyleClass.HOME_PRESET);
        button.trackHover();
        button.trackPress();
        button.registerEvent(MouseEvent.CLICK, _ -> onPreset(timeControl));

        var content:Box = narrow ? new HBox() : new VBox();
        content.addClass(StyleClass.HOME_PRESET_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        button.addComponent(content);

        var valueLine:HBox = new HBox();
        valueLine.addClass(StyleClass.HOME_PRESET_VALUE_LINE);
        valueLine.horizontalAlign = "center";
        valueLine.verticalAlign = "center";
        content.addComponent(valueLine);

        valueLine.addComponent(new TimeControlKindIcon(timeControl.getKind()));

        var valueLabel:Label = new Label();
        valueLabel.text = TimeControlFormatters.formatFischerTimeControl(timeControl);
        valueLabel.addClass(StyleClass.HOME_PRESET_VALUE);
        valueLabel.verticalAlign = "center";
        valueLine.addComponent(valueLabel);

        var kindLabel:Label = new Label();
        kindLabel.text = LocaleUtils.localeBinding('intellector.common.time_control_kind.${timeControl.getKind().getName().toLowerCase()}');
        kindLabel.addClass(StyleClass.HOME_PRESET_KIND);
        kindLabel.horizontalAlign = "center";
        kindLabel.verticalAlign = "center";
        content.addComponent(kindLabel);

        return button;
    }
}
