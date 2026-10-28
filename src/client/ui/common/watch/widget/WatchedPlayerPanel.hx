package client.ui.common.watch.widget;

import client.ServerTime;
import client.datatypes.game.OngoingGame;
import client.datatypes.player.PlayerStatus;
import client.datatypes.watch.WatchedPlayer;
import client.formatters.PlayerSearchFormatters;
import client.ui.common.StatusDot;
import client.ui.common.games.widget.OngoingGameEntry;
import client.utils.PagePaths;
import haxe.ui.backend.html5.svg.SVGPathBuilder;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.ByMenuLayout;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import haxefolio.ResponsivityController;
import haxefolio.graphics.SvgSurface;
import morestd.Detachable;

using client.ui.ComponentExtension;

/**
    The watch widget's content while watching: the player (their status, a link to their profile),
    Stop watching, and their ongoing games, newest first.
**/
class WatchedPlayerPanel extends VBox
{
    private static inline final CHEVRON:String = "M6 3.5L10.5 8L6 12.5";
    private static inline final CHEVRON_SIZE:Float = 16;

    private final onFollowed:Void->Void;
    private final onPreviewToggled:OngoingGameEntry->Bool->Void;
    private final playerRow:HBox;
    private final statusDot:StatusDot;
    private final nicknameLabel:Label;
    private final statusLabel:Label;
    private final profileLink:PageLink;
    private final gameCount:Label;
    private final entries:VBox;
    private final noGames:Label;
    private final breakpointBinding:Detachable;

    private var games:Array<OngoingGame> = [];
    private var currentGameId:Null<Int> = null;
    private var entryMap:Map<Int, OngoingGameEntry> = [];

    /** `onFollowed`: a link in it was used to navigate in the app **/
    public function new(onStop:Void->Void, onFollowed:Void->Void, onPreviewToggled:OngoingGameEntry->Bool->Void)
    {
        super();

        this.onFollowed = onFollowed;
        this.onPreviewToggled = onPreviewToggled;
        percentWidth = 100;
        addClass(StyleClass.WATCH_PANEL);

        var summary:VBox = new VBox();
        summary.percentWidth = 100;
        summary.addClass(StyleClass.WATCH_SUMMARY);
        addComponent(summary);

        var heading:Label = new Label();
        heading.text = LocaleUtils.localeBinding("intellector.watch_widget.watching");
        heading.addClass(StyleClass.WATCH_HEADING);
        summary.addComponent(heading);

        playerRow = new HBox();
        playerRow.percentWidth = 100;
        playerRow.addClass(StyleClass.WATCH_PLAYER_ROW);
        playerRow.trackHover();
        profileLink = PageLink.attach(playerRow, null, null, null, onFollowed);
        summary.addComponent(playerRow);

        statusDot = new StatusDot(Offline);
        playerRow.addComponent(statusDot);

        nicknameLabel = new Label();
        nicknameLabel.percentWidth = 100;
        nicknameLabel.verticalAlign = "center";
        nicknameLabel.addClass(StyleClass.WATCH_PLAYER_NICKNAME);
        playerRow.addComponent(nicknameLabel);

        statusLabel = new Label();
        statusLabel.verticalAlign = "center";
        statusLabel.addClass(StyleClass.WATCH_PLAYER_STATUS);
        playerRow.addComponent(statusLabel);

        var chevronBox:Box = new Box();
        chevronBox.width = CHEVRON_SIZE;
        chevronBox.height = CHEVRON_SIZE;
        chevronBox.verticalAlign = "center";
        playerRow.addComponent(chevronBox);

        var chevron:SvgSurface = new SvgSurface(CHEVRON_SIZE, CHEVRON_SIZE);
        chevron.element.setAttribute("aria-hidden", "true");
        chevronBox.addComponent(chevron);
        var chevronPath:SVGPathBuilder = chevron.svgPath(0, 0);
        chevronPath.element.setAttribute("d", CHEVRON);
        chevronPath.element.setAttribute("fill", "none");
        chevronPath.element.setAttribute("stroke", StyleVars.WATCH_PLAYER_CHEVRON);
        chevronPath.element.setAttribute("stroke-width", "1.4");
        chevronPath.element.setAttribute("stroke-linecap", "round");
        chevronPath.element.setAttribute("stroke-linejoin", "round");

        var stopButton:Button = new Button();
        stopButton.text = LocaleUtils.localeBinding("intellector.watch_widget.stop");
        stopButton.percentWidth = 100;
        stopButton.addClass(StyleClass.CHALLENGE_ENTRY_ACTION);
        stopButton.addClass(StyleClass.WATCH_STOP);
        stopButton.onClick = _ -> onStop();
        summary.addComponent(stopButton);

        var header:HBox = new HBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.CHALLENGE_LIST_HEADER);
        header.addClass(StyleClass.GAME_LIST_HEADER_DIVIDED);
        addComponent(header);

        var headerName:Label = new Label();
        headerName.text = LocaleUtils.localeBinding("intellector.watch_widget.games");
        headerName.verticalAlign = "center";
        headerName.addClass(StyleClass.CHALLENGE_LIST_HEADER_NAME);
        header.addComponent(headerName);

        gameCount = new Label();
        gameCount.verticalAlign = "center";
        gameCount.addClass(StyleClass.CHALLENGE_LIST_HEADER_COUNT);
        header.addComponent(gameCount);

        entries = new VBox();
        entries.percentWidth = 100;
        entries.addClass(StyleClass.CHALLENGE_LIST_ENTRIES);
        addComponent(entries);

        noGames = new Label();
        noGames.percentWidth = 100;
        noGames.text = LocaleUtils.localeBinding("intellector.watch_widget.no_games");
        noGames.addClass(StyleClass.CHALLENGE_LIST_EMPTY);
        addComponent(noGames);

        // entries are laid out for one breakpoint, so they're rebuilt for the other
        var breakpoint:ByMenuLayout<Bool> = {expanded: false, collapsed: true};
        breakpointBinding = ResponsivityController.bind(breakpoint, _ -> rebuild());
    }

    public function setPlayer(player:WatchedPlayer):Void
    {
        nicknameLabel.text = player.nickname;
        profileLink.setPath(PagePaths.playerProfile(player.login));
        playerRow.element.setAttribute("aria-label", LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watch_widget.open_profile"), player.nickname));
    }

    public function setStatus(status:PlayerStatus):Void
    {
        statusDot.setStatus(status);
        statusLabel.text = PlayerSearchFormatters.status(status);
    }

    /** `currentGameId` is the game open on the page, if any **/
    public function setGames(games:Array<OngoingGame>, currentGameId:Null<Int>):Void
    {
        this.games = games;
        this.currentGameId = currentGameId;
        update();
    }

    public function findEntry(id:Int):Null<OngoingGameEntry>
    {
        return entryMap.get(id);
    }

    /** Refreshes every clock and time since the last move **/
    public function updateTime():Void
    {
        var nowMs:Float = ServerTime.now();
        for (entry in entryMap)
            entry.updateTime(nowMs);
    }

    public function dispose():Void
    {
        breakpointBinding.detach();
    }

    private function rebuild():Void
    {
        for (entry in entryMap)
            entries.removeComponent(entry, true);

        entryMap = [];
        update();
    }

    private function update():Void
    {
        var ordered:Array<OngoingGame> = games.copy();
        ordered.sort((a, b) -> b.id - a.id);

        var shownIds:Map<Int, Bool> = [for (game in ordered) game.id => true];
        var goneIds:Array<Int> = [for (id in entryMap.keys()) if (!shownIds.exists(id)) id];
        for (id in goneIds)
        {
            entries.removeComponent(entryMap.get(id), true);
            entryMap.remove(id);
        }

        for (i in 0...ordered.length)
        {
            var game:OngoingGame = ordered[i];
            var entry:Null<OngoingGameEntry> = entryMap.get(game.id);

            if (entry == null)
            {
                entry = new OngoingGameEntry(game, onFollowed, true);
                entry.onPreviewToggled = onPreviewToggled.bind(entry);
                entries.addComponentAt(entry, i);
                entryMap.set(game.id, entry);
            }
            else
            {
                entry.setGame(game);
                if (entries.getComponentIndex(entry) != i)
                    entries.setComponentIndex(entry, i);
            }

            entry.setFirst(i == 0);
            entry.setCurrent(game.id == currentGameId);
        }

        gameCount.text = Std.string(ordered.length);
        entries.hidden = ordered.length == 0;
        noGames.hidden = ordered.length > 0;
    }
}
