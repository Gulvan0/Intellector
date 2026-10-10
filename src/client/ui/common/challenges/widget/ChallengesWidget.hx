package client.ui.common.challenges.widget;

import client.datatypes.IncomingChallenge;
import client.datatypes.OutgoingChallenge;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.menu.DropdownWidget;
import morestd.Detachable;

/**
    The menu bar's challenges widget: the icon with the incoming count, and a dropdown listing every
    pending challenge. A custom position's preview opens beside the dropdown, or over its top on a
    narrow screen; one at a time, and never past the dropdown's closing or its entry's leaving.
**/
class ChallengesWidget
{
    /** What goes into the menu bar **/
    public final dropdown:DropdownWidget;

    /** Set once, before the first `render` **/
    public var handlers:ChallengesWidgetHandlers = {
        onAccept: _ -> {},
        onDecline: _ -> {},
        onCancel: _ -> {},
        onPreviewOpened: () -> {}
    };

    private final icon:ChallengesIcon;
    private final list:ChallengeList;

    private var previewEntry:Null<ChallengeEntry> = null;
    private var preview:Null<PositionPreviewPopover> = null;
    private var previewAnchoring:Null<Detachable> = null;

    public function new()
    {
        icon = new ChallengesIcon();
        list = new ChallengeList(
            {
                onAccept: id -> handlers.onAccept(id),
                onDecline: id -> handlers.onDecline(id),
                onCancel: id -> handlers.onCancel(id),
                onPreviewOpened: () -> handlers.onPreviewOpened()
            },
            onPreviewToggled
        );
        dropdown = new DropdownWidget(icon, list, StyleVars.CHALLENGES_DROPDOWN_WIDTH);
        dropdown.onClosed = closePreview;
    }

    /** `incoming` and `outgoing` in arrival order **/
    public function render(incoming:Array<IncomingChallenge>, outgoing:Array<OutgoingChallenge>, accepting:Bool, hasUnseenIncoming:Bool):Void
    {
        list.render(incoming, outgoing, accepting);

        icon.setState(incoming.length > 0, outgoing.length > 0, hasUnseenIncoming);
        dropdown.setBadgeCount(incoming.length);
        dropdown.setAccessibleName(LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.challenges_widget.accessible_name"), incoming.length, outgoing.length));

        if (previewEntry != null && list.findEntry(previewEntry.challengeId) != previewEntry)
            closePreview();
    }

    public function highlightArrival(id:Int):Void
    {
        var entry:Null<ChallengeEntry> = list.findEntry(id);
        if (entry != null)
            entry.highlightArrival();
    }

    public function closePreview():Void
    {
        if (previewEntry == null)
            return;

        var entry:ChallengeEntry = previewEntry;
        previewEntry = null;

        if (previewAnchoring != null)
        {
            previewAnchoring.detach();
            previewAnchoring = null;
            dropdown.detach(preview);
        }
        else
            dropdown.setCover(null);

        preview = null;
        entry.setPreviewSelected(false);
    }

    private function onPreviewToggled(entry:ChallengeEntry, selected:Bool):Void
    {
        if (!selected)
        {
            if (entry == previewEntry)
                closePreview();
            return;
        }

        closePreview();
        previewEntry = entry;

        if (ResponsivityController.isCollapsed)
        {
            preview = new PositionPreviewPopover(entry.customStartingPosition, entry.ownColor, entry.previewTitle(), closePreview);
            preview.addClass(StyleClass.CHALLENGE_PREVIEW_COVER);
            dropdown.setCover(preview);
        }
        else
        {
            preview = new PositionPreviewPopover(entry.customStartingPosition, entry.ownColor, entry.previewTitle());
            dropdown.attach(preview);

            var placement:AnchorPlacement = {side: Left, align: Start};
            previewAnchoring = Anchoring.attach(preview, dropdown.frame, placement);
        }

        handlers.onPreviewOpened();
    }
}
