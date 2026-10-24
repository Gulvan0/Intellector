package client.ui.changelog;

import client.datatypes.changelog.ChangelogEntry;
import client.logic.changelog.Changelog;
import client.ui.common.WidthObserver;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;
import morestd.Detachable;

class ChangelogPage extends PageBase
{
    private static inline final MAX_WIDTH:Float = 920;
    private static inline final STACKED_BELOW_WIDTH:Float = 532;
    private static inline final FRAME_PADDING:Float = 22;
    private static inline final CARD_PADDING:Float = 26;
    private static inline final CARD_BORDER:Float = 1;

    private final rows:Array<ChangelogRow> = [];

    private var frame:Null<VBox> = null;
    private var widthHandle:Null<Detachable> = null;

    public function new()
    {
        super();
    }

    private override function init():Void
    {
        setTitle(LocaleUtils.localeBinding("intellector.changelog.title"));

        frame = new VBox();
        frame.horizontalAlign = "center";
        frame.addClass(StyleClass.CHANGELOG_FRAME);
        addComponent(frame);

        var heading:Label = new Label();
        heading.text = LocaleUtils.localeBinding("intellector.changelog.title");
        heading.addClass(StyleClass.CHANGELOG_HEADING);
        frame.addComponent(heading);

        var card:VBox = new VBox();
        card.percentWidth = 100;
        card.addClass(StyleClass.CHANGELOG_CARD);
        frame.addComponent(card);

        var entries:Array<ChangelogEntry> = Changelog.load();
        for (i in 0...entries.length)
        {
            var row:ChangelogRow = new ChangelogRow(entries[i], i == 0);
            rows.push(row);
            card.addComponent(row);
        }

        widthHandle = WidthObserver.observe(this, onWidth);
    }

    private function onWidth(width:Float):Void
    {
        var frameWidth:Float = Math.min(width, MAX_WIDTH);
        frame.width = frameWidth;

        var innerWidth:Float = frameWidth - 2 * (FRAME_PADDING + CARD_BORDER + CARD_PADDING);
        for (row in rows)
            row.fit(innerWidth, frameWidth < STACKED_BELOW_WIDTH);
    }

    private override function onClose():Void
    {
        if (widthHandle != null)
            widthHandle.detach();
    }
}
