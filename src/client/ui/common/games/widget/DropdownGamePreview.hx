package client.ui.common.games.widget;

import client.datatypes.game.OngoingGame;
import client.ui.common.challenges.PositionPreviewPopover;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.MenuLayout;
import haxefolio.ResponsivityController;
import haxefolio.menu.DropdownWidget;
import morestd.Detachable;

/**
    The position of an ongoing game listed in a dropdown, previewed beside it, or over its top on a
    narrow screen; one at a time, and never past the dropdown's closing or its game's ending.
**/
class DropdownGamePreview
{
    private final dropdown:DropdownWidget;
    private final title:OngoingGame->String;

    private var entry:Null<OngoingGameEntry> = null;
    private var anchoring:Null<Detachable> = null;
    private var popover:Null<PositionPreviewPopover> = null;

    /** `title` names a game's preview **/
    public function new(dropdown:DropdownWidget, title:OngoingGame->String)
    {
        this.dropdown = dropdown;
        this.title = title;
    }

    /** For an entry's Preview button **/
    public function onToggled(entry:OngoingGameEntry, selected:Bool):Void
    {
        if (!selected)
        {
            if (entry == this.entry)
                close();
            return;
        }

        close();
        show(entry);
    }

    /**
        After the list is rendered: closes the preview of a game whose entry `findEntry` no longer
        gives, shows the current position of one that goes on.
    **/
    public function refresh(findEntry:Int->Null<OngoingGameEntry>):Void
    {
        var shownEntry:Null<OngoingGameEntry> = entry;
        if (shownEntry == null)
            return;

        if (findEntry(shownEntry.game.id) != shownEntry)
            close();
        else if (popover != null && popover.position != shownEntry.game.position)
            show(shownEntry);
    }

    public function close():Void
    {
        var shownEntry:Null<OngoingGameEntry> = entry;
        if (shownEntry == null)
            return;

        entry = null;
        remove();
        shownEntry.setPreviewSelected(false);
    }

    private function remove():Void
    {
        if (anchoring != null)
        {
            anchoring.detach();
            anchoring = null;
            dropdown.detach(popover);
        }
        else
            dropdown.setCover(null);

        popover = null;
    }

    private function show(entry:OngoingGameEntry):Void
    {
        if (popover != null)
            remove();

        this.entry = entry;

        var game:OngoingGame = entry.game;

        if (ResponsivityController.menuLayout != Expanded)
        {
            popover = new PositionPreviewPopover(game.position, game.ownColor, title(game), close);
            popover.addClass(StyleClass.CHALLENGE_PREVIEW_COVER);
            dropdown.setCover(popover);
        }
        else
        {
            popover = new PositionPreviewPopover(game.position, game.ownColor, title(game));
            dropdown.attach(popover);

            var placement:AnchorPlacement = {side: Left, align: Start};
            anchoring = Anchoring.attach(popover, dropdown.frame, placement);
        }
    }
}
