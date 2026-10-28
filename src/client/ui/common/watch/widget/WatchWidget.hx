package client.ui.common.watch.widget;

import client.datatypes.game.OngoingGame;
import client.datatypes.player.PlayerStatus;
import client.datatypes.watch.WatchedPlayer;
import client.formatters.PlayerSearchFormatters;
import client.ui.common.games.widget.DropdownGamePreview;
import haxe.Timer;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.menu.DropdownWidget;

/**
    The menu bar's watch widget: the eye icon, mirroring the watched player's status, and a dropdown
    either picking a player to watch or showing the watched one with their ongoing games, whose
    clocks run while it's open and whose positions can be previewed.
**/
class WatchWidget
{
    private static inline final TICK_INTERVAL_MS:Int = 1000;

    /** What goes into the menu bar **/
    public final dropdown:DropdownWidget;

    /** Tells which game the page shows, if any; asked on every render **/
    public var currentGameId:Void->Null<Int> = () -> null;

    private final icon:WatchIcon;
    private final form:WatchForm;
    private final panel:WatchedPlayerPanel;
    private final preview:DropdownGamePreview;

    private var player:Null<WatchedPlayer> = null;
    private var status:PlayerStatus = Offline;
    private var games:Array<OngoingGame> = [];
    private var ticker:Null<Timer> = null;

    public function new(onWatched:WatchedPlayer->Void, onStopped:Void->Void)
    {
        icon = new WatchIcon();
        form = new WatchForm(onWatched, reopen);
        panel = new WatchedPlayerPanel(onStopped, closeDropdown, (entry, selected) -> preview.onToggled(entry, selected));

        var content:VBox = new VBox();
        content.addComponent(form);
        content.addComponent(panel);

        dropdown = new DropdownWidget(icon, content, StyleVars.WATCH_DROPDOWN_WIDTH);
        preview = new DropdownGamePreview(dropdown, previewTitle);
        dropdown.onOpened = onDropdownOpened;
        dropdown.onClosed = onDropdownClosed;

        render();
    }

    /** Null: watching no one **/
    public function setPlayer(player:Null<WatchedPlayer>):Void
    {
        if (player?.login != this.player?.login)
        {
            status = Offline;
            games = [];
            form.reset();
        }

        this.player = player;
        render();
    }

    public function setStatus(status:PlayerStatus):Void
    {
        this.status = status;
        render();
    }

    public function setGames(games:Array<OngoingGame>):Void
    {
        this.games = games;
        render();
    }

    private function render():Void
    {
        form.hidden = player != null;
        panel.hidden = player == null;
        icon.setStatus(player != null ? status : null);

        if (player == null)
        {
            preview.close();
            dropdown.setAccessibleName(LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watch_widget.accessible_name.idle")));
            return;
        }

        panel.setPlayer(player);
        panel.setStatus(status);
        panel.setGames(games, currentGameId());
        preview.refresh(panel.findEntry);
        dropdown.setAccessibleName(LocaleUtils.resolveText(
            LocaleUtils.localeBinding("intellector.watch_widget.accessible_name.watching"),
            player.nickname,
            LocaleUtils.resolveText(PlayerSearchFormatters.status(status))
        ));
    }

    private function reopen():Void
    {
        dropdown.open();
    }

    private function closeDropdown():Void
    {
        dropdown.close();
    }

    private function onDropdownOpened():Void
    {
        icon.setOpen(true);
        render();

        ticker = new Timer(TICK_INTERVAL_MS);
        ticker.run = panel.updateTime;
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
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watch_widget.preview_title"), game.opponentNickname);
    }
}
