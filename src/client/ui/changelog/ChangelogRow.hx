package client.ui.changelog;

import client.datatypes.changelog.ChangelogEntry;
import client.formatters.ProfileFormatters;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;

/**
    One update: its date beside the title and description, or above them once stacked. The number
    among same-day updates goes under the date when beside, and on the date's line when stacked.
    An update without a description is a compact title-only row.
**/
class ChangelogRow extends VBox
{
    private static inline final DATE_COLUMN_WIDTH:Float = 110;
    private static inline final COLUMN_GAP:Float = 26;
    private static inline final MAX_PARAGRAPHS_WIDTH:Float = 600;

    private final entry:ChangelogEntry;
    private final dateColumn:VBox;
    private final dateLine:HBox;
    private final dateLabel:Label;
    private var numberLabel:Null<Label> = null;
    private final textColumn:VBox;
    private final paragraphs:VBox;
    private final sideBySide:HBox;
    private final stackedBox:VBox;

    private var stacked:Null<Bool> = null;

    public function new(entry:ChangelogEntry, first:Bool)
    {
        super();
        this.entry = entry;
        percentWidth = 100;
        addClass(StyleClass.CHANGELOG_ROW);
        addClass(entry.hasDescription() ? StyleClass.CHANGELOG_ROW_DESCRIBED : StyleClass.CHANGELOG_ROW_COMPACT);
        if (first)
            addClass(StyleClass.CHANGELOG_ROW_FIRST);

        dateColumn = new VBox();
        dateColumn.width = DATE_COLUMN_WIDTH;
        dateColumn.addClass(StyleClass.CHANGELOG_DATE_COLUMN);

        dateLine = new HBox();
        dateLine.percentWidth = 100;
        dateLine.addClass(StyleClass.CHANGELOG_DATE_INLINE);

        dateLabel = new Label();
        dateLabel.addClass(StyleClass.CHANGELOG_DATE);
        LocaleManager.instance.registerComponent(dateLabel, "text", formatDate);

        if (entry.sameDayNumber != null)
        {
            numberLabel = new Label();
            numberLabel.text = '#${entry.sameDayNumber}';
            numberLabel.addClass(StyleClass.CHANGELOG_NUMBER);
        }

        textColumn = new VBox();
        textColumn.addClass(StyleClass.CHANGELOG_TEXT_COLUMN);

        var titleLabel:Label = new Label();
        titleLabel.percentWidth = 100;
        titleLabel.addClass(entry.hasDescription() ? StyleClass.CHANGELOG_TITLE_DESCRIBED : StyleClass.CHANGELOG_TITLE_COMPACT);
        textColumn.addComponent(titleLabel);
        LocaleManager.instance.registerComponent(titleLabel, "text", () -> entry.title(LocaleManager.instance.language));

        paragraphs = new VBox();
        paragraphs.addClass(StyleClass.CHANGELOG_PARAGRAPHS);
        if (entry.hasDescription())
        {
            for (i in 0...entry.paragraphs("en").length)
            {
                var paragraphLabel:Label = new Label();
                paragraphLabel.percentWidth = 100;
                paragraphLabel.addClass(StyleClass.CHANGELOG_PARAGRAPH);
                paragraphs.addComponent(paragraphLabel);
                LocaleManager.instance.registerComponent(paragraphLabel, "text", () -> entry.paragraphs(LocaleManager.instance.language)[i]);
            }
            textColumn.addComponent(paragraphs);
        }

        sideBySide = new HBox();
        sideBySide.percentWidth = 100;
        sideBySide.addClass(StyleClass.CHANGELOG_SIDE_BY_SIDE);

        stackedBox = new VBox();
        stackedBox.percentWidth = 100;
        stackedBox.addClass(StyleClass.CHANGELOG_STACKED);
    }

    /** `innerWidth` is the width the row's content gets **/
    public function fit(innerWidth:Float, stacked:Bool):Void
    {
        var textWidth:Float = stacked ? innerWidth : innerWidth - DATE_COLUMN_WIDTH - COLUMN_GAP;
        paragraphs.width = Math.min(MAX_PARAGRAPHS_WIDTH, textWidth);
        textColumn.width = textWidth;

        if (this.stacked == stacked)
            return;
        this.stacked = stacked;

        var dateParts:Array<Component> = numberLabel != null ? [dateLabel, numberLabel] : [dateLabel];
        for (part in dateParts.concat([dateColumn, dateLine, textColumn, sideBySide, stackedBox]))
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);

        var dateContainer:Box = stacked ? dateLine : dateColumn;
        for (part in dateParts)
        {
            part.percentWidth = stacked ? null : 100;
            if (stacked)
                part.width = null;
            part.verticalAlign = stacked ? "center" : "top";
            dateContainer.addComponent(part);
            part.invalidateComponentLayout(); // the width that was dropped is not re-measured otherwise
        }

        if (stacked)
        {
            stackedBox.addComponent(dateLine);
            stackedBox.addComponent(textColumn);
            addComponent(stackedBox);
        }
        else
        {
            sideBySide.addComponent(dateColumn);
            sideBySide.addComponent(textColumn);
            addComponent(sideBySide);
        }
    }

    private function formatDate():String
    {
        return ProfileFormatters.shortDateWithYear(new Date(entry.year, entry.month - 1, entry.day, 0, 0, 0).getTime());
    }
}
