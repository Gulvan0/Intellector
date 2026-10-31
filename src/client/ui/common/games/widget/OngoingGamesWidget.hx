package client.ui.common.games.widget;

import client.datatypes.game.OngoingGame;
import client.ui.common.games.widget.OngoingGamesIcon.OngoingGamesSignal;
import haxe.Timer;
import haxefolio.LocaleUtils;
import haxefolio.menu.DropdownWidget;

/**
    The menu bar's ongoing games widget: the icon with the count of timed games on the user's move,
    and a dropdown listing every ongoing game, its clocks running while it's open, each one's
    position previewable.
**/
class OngoingGamesWidget
{
    private static inline final TICK_INTERVAL_MS:Int = 1000;

    /** What goes into the menu bar **/
    public final dropdown:DropdownWidget;

    /** Tells which game the page shows, if any; asked on every render **/
    public var currentGameId:Void->Null<Int> = () -> null;

    private final icon:OngoingGamesIcon;
    private final list:OngoingGameList;
    private final preview:DropdownGamePreview;

    private var games:Array<OngoingGame> = [];
    private var ticker:Null<Timer> = null;

    public function new()
    {
        icon = new OngoingGamesIcon();
        list = new OngoingGameList(closeDropdown, (entry, selected) -> preview.onToggled(entry, selected));
        dropdown = new DropdownWidget(icon, list, StyleVars.GAMES_DROPDOWN_WIDTH);
        preview = new DropdownGamePreview(dropdown, previewTitle);
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

        preview.refresh(list.findEntry);
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

    private function closeDropdown():Void
    {
        dropdown.close();
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
        preview.close();

        if (ticker != null)
        {
            ticker.stop();
            ticker = null;
        }
    }

    private static function previewTitle(game:OngoingGame):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games_widget.game_with"), LocaleUtils.resolveText(game.opponentNickname));
    }
}
