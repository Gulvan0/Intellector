package client.ui.common.games.widget;

import client.datatypes.OngoingGame;
import client.ui.common.challenges.PositionPreviewPopover;
import client.ui.common.games.widget.OngoingGamesIcon.OngoingGamesSignal;
import haxe.Timer;
import haxefolio.AnchorPlacement;
import haxefolio.Anchoring;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.menu.DropdownWidget;
import morestd.Detachable;

/**
    The menu bar's ongoing games widget: the icon with the count of timed games on the user's move,
    and a dropdown listing every ongoing game, its clocks running while it's open. A game's position
    previews beside the dropdown, or over its top on a narrow screen; one at a time, and never past
    the dropdown's closing or its game's ending.
**/
class OngoingGamesWidget
{
    private static inline final TICK_INTERVAL_MS:Int = 1000;

    /** What goes into the menu bar **/
    public final dropdown:DropdownWidget;

    /** Called with the id of the game to open, once the dropdown is closed **/
    public var onOpen:Int->Void = _ -> {};

    /** Tells which game the page shows, if any; asked on every render **/
    public var currentGameId:Void->Null<Int> = () -> null;

    private final icon:OngoingGamesIcon;
    private final list:OngoingGameList;

    private var games:Array<OngoingGame> = [];
    private var ticker:Null<Timer> = null;

    private var previewEntry:Null<OngoingGameEntry> = null;
    private var previewAnchoring:Null<Detachable> = null;
    private var preview:Null<PositionPreviewPopover> = null;

    public function new()
    {
        icon = new OngoingGamesIcon();
        list = new OngoingGameList(open, onPreviewToggled);
        dropdown = new DropdownWidget(icon, list, StyleVars.GAMES_DROPDOWN_WIDTH);
        dropdown.onOpened = onDropdownOpened;
        dropdown.onClosed = onDropdownClosed;

        render([]);
    }

    public function render(games:Array<OngoingGame>):Void
    {
        this.games = games;
        list.render(games, currentGameId());

        var timedOwnMoveCount:Int = games.filter(game -> game.isTimed() && game.isOwnMove()).length;
        var correspondenceOwnMoveCount:Int = games.filter(game -> !game.isTimed() && game.isOwnMove()).length;
        var opponentMoveCount:Int = games.length - timedOwnMoveCount - correspondenceOwnMoveCount;

        icon.setSignal(signal(timedOwnMoveCount, correspondenceOwnMoveCount, opponentMoveCount));
        dropdown.setBadgeCount(timedOwnMoveCount);
        dropdown.setAccessibleName(LocaleUtils.resolveText(
            LocaleUtils.localeBinding("intellector.games_widget.accessible_name"),
            timedOwnMoveCount,
            correspondenceOwnMoveCount,
            opponentMoveCount
        ));

        refreshPreview();
    }

    private static function signal(timedOwnMoveCount:Int, correspondenceOwnMoveCount:Int, opponentMoveCount:Int):OngoingGamesSignal
    {
        if (timedOwnMoveCount > 0)
            return TimedOwnMove;
        else if (correspondenceOwnMoveCount > 0)
            return CorrespondenceOwnMove;
        else if (opponentMoveCount > 0)
            return OpponentMoveOnly;
        else
            return NoGames;
    }

    private function open(gameId:Int):Void
    {
        dropdown.close();
        onOpen(gameId);
    }

    private function onDropdownOpened():Void
    {
        icon.setOpen(true);
        render(games);

        ticker = new Timer(TICK_INTERVAL_MS);
        ticker.run = list.updateTime;
    }

    private function onDropdownClosed():Void
    {
        icon.setOpen(false);
        closePreview();

        if (ticker != null)
        {
            ticker.stop();
            ticker = null;
        }
    }

    // after a render: closes the preview of a game that has ended, shows the current position of one that goes on
    private function refreshPreview():Void
    {
        var entry:Null<OngoingGameEntry> = previewEntry;
        if (entry == null)
            return;

        if (list.findEntry(entry.game.id) != entry)
            closePreview();
        else if (preview != null && preview.position != entry.game.position)
            showPreview(entry);
    }

    private function closePreview():Void
    {
        var entry:Null<OngoingGameEntry> = previewEntry;
        if (entry == null)
            return;

        previewEntry = null;
        removePreview();
        entry.setPreviewSelected(false);
    }

    private function removePreview():Void
    {
        if (previewAnchoring != null)
        {
            previewAnchoring.detach();
            previewAnchoring = null;
            dropdown.detach(preview);
        }
        else
            dropdown.setCover(null);

        preview = null;
    }

    private function onPreviewToggled(entry:OngoingGameEntry, selected:Bool):Void
    {
        if (!selected)
        {
            if (entry == previewEntry)
                closePreview();
            return;
        }

        closePreview();
        showPreview(entry);
    }

    private function showPreview(entry:OngoingGameEntry):Void
    {
        if (preview != null)
            removePreview();

        previewEntry = entry;

        var game:OngoingGame = entry.game;
        var title:String = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games_widget.game_with"), game.opponentNickname);

        if (ResponsivityController.isCollapsed)
        {
            preview = new PositionPreviewPopover(game.position, game.ownColor, title, closePreview);
            preview.addClass(StyleClass.CHALLENGE_PREVIEW_COVER);
            dropdown.setCover(preview);
        }
        else
        {
            preview = new PositionPreviewPopover(game.position, game.ownColor, title);
            dropdown.attach(preview);

            var placement:AnchorPlacement = {side: Left, align: Start};
            previewAnchoring = Anchoring.attach(preview, dropdown.frame, placement);
        }
    }
}
