package client.ui.profile;

import client.ServerTime;
import client.datatypes.game.GameRecord;
import client.datatypes.timecontrol.TimeControlKind;
import client.formatters.OngoingGameFormatters;
import client.ui.common.FilterDropdown;
import client.ui.common.LoadStatus;
import client.ui.common.UnderlineTabs;
import client.ui.common.WidthObserver;
import client.ui.common.games.GameCard;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;
import intellectorboard.primitives.piece.PieceColor;
import morestd.Detachable;

/**
    The player's ongoing games: live ones and correspondence ones as two tabs sharing one filter row
    (on the Correspondence tab, the time control facet stays, disabled). Up to two rows of cards are
    shown; more scroll, with a sliver of the next row showing.
**/
class OngoingGamesCard extends VBox
{
    private static final TIMED_KINDS:Array<TimeControlKind> = [Hyperbullet, Bullet, Blitz, Rapid, Classic];
    private static final TYPE_RATED:Array<Null<Bool>> = [null, true, false];

    private static inline final TWO_COLUMNS_MIN_WIDTH:Float = 680;
    // a correspondence card's head line ("Correspondence · Rated", longest in Russian) needs wider cards
    private static inline final CORRESPONDENCE_TWO_COLUMNS_MIN_WIDTH:Float = 780;
    private static inline final CARD_HEIGHT:Float = 138;
    private static inline final CARD_GAP:Float = 14;
    private static inline final PANEL_VERTICAL_PADDING:Float = 28;
    private static inline final PANEL_HORIZONTAL_PADDING:Float = 28;
    private static inline final NEXT_ROW_SLIVER:Float = 40;
    private static inline final MAX_FULL_ROWS:Int = 2;

    private final login:String;

    private final tabs:UnderlineTabs;
    private final kindFilter:FilterDropdown;
    private final typeFilter:FilterDropdown;
    private final resetButton:Button;
    private final loadStatus:LoadStatus;
    private final panel:Box;
    private final grid:VBox;
    private final emptyLabel:Label;
    private final widthHandle:Detachable;

    private var games:Null<Array<GameRecord>> = null;
    private var onCorrespondence:Bool = false;
    private var selectedKinds:Array<TimeControlKind> = [];
    private var rated:Null<Bool> = null;
    private var columns:Int = 1;
    private var panelWidth:Float = 0;
    private var cards:Array<GameCard> = [];

    /** `login`: the profile's player, whose side the boards are seen from **/
    public function new(login:String)
    {
        super();
        this.login = login;
        percentWidth = 100;
        addClass(StyleClass.PROFILE_CARD);
        addClass(StyleClass.PROFILE_SECTION);

        tabs = new UnderlineTabs([
            LocaleUtils.localeBinding("intellector.profile.ongoing.live"),
            LocaleUtils.localeBinding("intellector.profile.ongoing.correspondence")
        ], true, index -> {
            onCorrespondence = index == 1;
            render();
        });
        tabs.addClass(StyleClass.PROFILE_SECTION_TABS);
        addComponent(tabs);

        var filterRow:HBox = new HBox();
        filterRow.percentWidth = 100;
        filterRow.continuous = true;
        filterRow.addClass(StyleClass.PROFILE_FILTER_ROW);
        addComponent(filterRow);

        kindFilter = new FilterDropdown(
            LocaleUtils.localeBinding("intellector.common.filter.time_control"),
            [for (kind in TIMED_KINDS) {caption: LocaleUtils.localeBinding('intellector.common.time_control_kind.${kind.getName().toLowerCase()}'), kind: kind}],
            true,
            250,
            selection -> {
                selectedKinds = [for (i in selection) TIMED_KINDS[i]];
                render();
            },
            LocaleUtils.localeBinding("intellector.common.filter.any_hint")
        );
        filterRow.addComponent(kindFilter);

        typeFilter = new FilterDropdown(
            LocaleUtils.localeBinding("intellector.common.filter.type"),
            [
                {caption: LocaleUtils.localeBinding("intellector.common.filter.any")},
                {caption: LocaleUtils.localeBinding("intellector.common.game_type.rated")},
                {caption: LocaleUtils.localeBinding("intellector.common.game_type.casual")}
            ],
            false,
            200,
            selection -> {
                rated = TYPE_RATED[selection[0]];
                render();
            }
        );
        filterRow.addComponent(typeFilter);

        resetButton = new Button();
        resetButton.text = LocaleUtils.localeBinding("intellector.common.filter.reset");
        resetButton.addClass(StyleClass.FILTER_RESET);
        resetButton.onClick = _ -> {
            selectedKinds = [];
            rated = null;
            render();
        };
        filterRow.addComponent(resetButton);

        loadStatus = new LoadStatus();
        loadStatus.addClass(StyleClass.PROFILE_SECTION_STATUS);
        addComponent(loadStatus);

        panel = new Box();
        panel.percentWidth = 100;
        panel.addClass(StyleClass.PROFILE_ONGOING_PANEL);
        panel.hidden = true;
        addComponent(panel);

        grid = new VBox();
        grid.percentWidth = 100;
        grid.addClass(StyleClass.PROFILE_CARD_GRID);
        var scrollArea:ScrollArea = new ScrollArea(grid);
        scrollArea.percentHeight = 100;
        panel.addComponent(scrollArea);

        emptyLabel = new Label();
        emptyLabel.addClass(StyleClass.PROFILE_MUTED);
        emptyLabel.horizontalAlign = "center";
        emptyLabel.verticalAlign = "center";
        emptyLabel.hidden = true;
        panel.addComponent(emptyLabel);

        widthHandle = WidthObserver.observe(panel, width -> {
            panelWidth = width;
            if (columnCount() != columns)
                render();
        });

        render();
    }

    public function showLoading():Void
    {
        loadStatus.showLoading();
        loadStatus.hidden = false;
        panel.hidden = true;
    }

    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        loadStatus.showFailure(timedOut, onRetry);
        loadStatus.hidden = false;
        panel.hidden = true;
    }

    /** `opening`: the first list since loading, which picks the tab: Live if there is a live game **/
    public function setGames(games:Array<GameRecord>, opening:Bool):Void
    {
        this.games = games;
        loadStatus.hidden = true;
        panel.hidden = false;
        if (opening)
            onCorrespondence = !Lambda.exists(games, isLive);
        render();
    }

    /** Refreshes the time since each correspondence game's last move **/
    public function refreshTimes():Void
    {
        for (card in cards)
            if (!isLive(card.game))
                setCardStatus(card);
    }

    public function dispose():Void
    {
        widthHandle.detach();
        kindFilter.close();
        typeFilter.close();
    }

    private function columnCount():Int
    {
        var minWidth:Float = onCorrespondence ? CORRESPONDENCE_TWO_COLUMNS_MIN_WIDTH : TWO_COLUMNS_MIN_WIDTH;
        return panelWidth - PANEL_HORIZONTAL_PADDING >= minWidth ? 2 : 1;
    }

    private function render():Void
    {
        tabs.selectedIndex = onCorrespondence ? 1 : 0;
        columns = columnCount();

        var all:Array<GameRecord> = games ?? [];
        var live:Array<GameRecord> = all.filter(isLive);
        var correspondence:Array<GameRecord> = all.filter(game -> !isLive(game));
        tabs.setCount(0, games != null ? live.filter(matchesFilters).length : null);
        tabs.setCount(1, games != null ? correspondence.filter(matchesRated).length : null);

        var pool:Array<GameRecord> = onCorrespondence ? correspondence : live;
        kindFilter.setSelection([for (i in 0...TIMED_KINDS.length) if (selectedKinds.contains(TIMED_KINDS[i])) i]);
        kindFilter.setLocked(onCorrespondence ? LocaleUtils.localeBinding("intellector.common.no_clock") : null);
        kindFilter.setCounts([for (kind in TIMED_KINDS) live.filter(game -> matchesRated(game) && game.timeControl.getKind() == kind).length]);

        var typePool:Array<GameRecord> = onCorrespondence ? pool : pool.filter(matchesKinds);
        typeFilter.setSelection([TYPE_RATED.indexOf(rated)]);
        typeFilter.setCounts([for (option in TYPE_RATED) typePool.filter(game -> option == null || game.rated == option).length]);

        resetButton.disabled = selectedKinds.length == 0 && rated == null;

        var shown:Array<GameRecord> = onCorrespondence ? pool.filter(matchesRated) : pool.filter(matchesFilters);
        renderCards(shown, pool.length == 0);
    }

    private function renderCards(shown:Array<GameRecord>, poolEmpty:Bool):Void
    {
        grid.removeAllComponents();
        cards = [];

        var row:Null<HBox> = null;
        for (i in 0...shown.length)
        {
            if (i % columns == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.PROFILE_CARD_ROW);
                grid.addComponent(row);
            }

            var game:GameRecord = shown[i];
            var card:GameCard = new GameCard(game, orientationOf(game));
            setCardStatus(card);
            cards.push(card);
            row.addComponent(card);
        }

        if (row != null && shown.length % columns != 0)
        {
            var filler:Box = new Box();
            filler.percentWidth = 100;
            row.addComponent(filler);
        }

        var rowCount:Int = Math.ceil(shown.length / columns);
        var fullRows:Int = Std.int(Math.max(1, Math.min(rowCount, MAX_FULL_ROWS)));
        panel.height = PANEL_VERTICAL_PADDING + CARD_HEIGHT * fullRows + CARD_GAP * (fullRows - 1) + (rowCount > MAX_FULL_ROWS ? NEXT_ROW_SLIVER : 0);

        emptyLabel.hidden = shown.length > 0;
        emptyLabel.text = LocaleUtils.localeBinding(switch [onCorrespondence, poolEmpty] {
            case [false, true]: "intellector.profile.ongoing.no_live";
            case [false, false]: "intellector.profile.ongoing.no_live_match";
            case [true, true]: "intellector.profile.ongoing.no_correspondence";
            case [true, false]: "intellector.profile.ongoing.no_correspondence_match";
        });
    }

    private function setCardStatus(card:GameCard):Void
    {
        var game:GameRecord = card.game;
        if (isLive(game))
            card.setStatus(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.ongoing.in_progress")), () -> "");
        else
        {
            var turnKey:String = 'intellector.common.turn_color.${game.position.turnColor.getName().toLowerCase()}';
            var waitedMs:Null<Float> = OngoingGameFormatters.elapsedSince(game.waitingSinceMs(), ServerTime.now());
            card.setStatus(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding(turnKey)), () -> OngoingGameFormatters.lastMoveAgoText(waitedMs));
        }
    }

    private function orientationOf(game:GameRecord):PieceColor
    {
        return game.colorOf(login) ?? White;
    }

    private function matchesFilters(game:GameRecord):Bool
    {
        return matchesKinds(game) && matchesRated(game);
    }

    private function matchesKinds(game:GameRecord):Bool
    {
        return selectedKinds.length == 0 || selectedKinds.contains(game.timeControl.getKind());
    }

    private function matchesRated(game:GameRecord):Bool
    {
        return rated == null || game.rated == rated;
    }

    private static function isLive(game:GameRecord):Bool
    {
        return !game.timeControl.match(None);
    }
}
