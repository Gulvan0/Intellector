package client.ui.home;

import client.ServerTime;
import client.datatypes.game.GameCounts;
import client.datatypes.game.GameEnding;
import client.datatypes.game.GameListFilter;
import client.datatypes.game.GameRecord;
import client.datatypes.timecontrol.TimeControlKind;
import client.formatters.GameFormatters;
import client.formatters.OngoingGameFormatters;
import client.ui.common.FilterDropdown;
import client.ui.common.LoadStatus;
import client.ui.common.Pager;
import client.ui.common.UnderlineTabs;
import client.ui.common.games.GameCard;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

enum GamesSectionKind
{
    /** Live games by default; correspondence ones only when that kind is picked **/
    Ongoing;
    /** The latest finished games, the latest ended first **/
    Recent;
}

typedef GamesSectionCallbacks =
{
    /** Recent only: the games to show are another list now, to be delivered with `setGames` **/
    onFilterChanged:GameListFilter->Void,
    /** Narrow only: one of the two tabs standing for the sections was clicked **/
    onTabSelected:Int->Void,
    onRetry:Void->Void
}

/**
    A games section: a heading (on a phone, the tabs switching between the sections), a filter
    bar and the game cards in a panel.

    Ongoing keeps every ongoing game, filters them locally and pages them, the page size following
    the column count, which follows the content width; a pill in the heading (on a phone, after
    the filters) says the shown page is behind when the games change on a page other than the
    first. Recent shows the latest `RECENT_SIZE` games the feed delivers, with no paging.
**/
class GamesSection extends VBox
{
    private static final KINDS:Array<TimeControlKind> = GameListFilter.KINDS;
    private static final TYPE_RATED:Array<Null<Bool>> = [null, true, false];

    private static inline final THREE_COLUMNS_MIN_WIDTH:Float = 1100;
    private static inline final TWO_COLUMNS_MIN_WIDTH:Float = 740;
    private static inline final CARD_GAP:Float = 14;
    private static inline final PANEL_PADDING:Float = 14;
    private static inline final SECTION_BORDERS_WIDTH:Float = 2;
    private static inline final NARROW_FILTER_ROW_HEIGHT:Float = 93;

    /** How many games the recent games feed delivers **/
    public static inline final RECENT_SIZE:Int = 12;

    public final kind:GamesSectionKind;
    public final filter:GameListFilter;

    private final callbacks:GamesSectionCallbacks;

    private final heading:HBox;
    private final titleLabel:Label;
    private final tabs:UnderlineTabs;
    private final pillButton:Button;
    private final filterRow:HBox;
    private final kindFilter:FilterDropdown;
    private final typeFilter:FilterDropdown;
    private final resetButton:Button;
    private final headingSpacer:Box;
    private final panel:Box;
    private final grid:VBox;
    private final loadStatus:LoadStatus;
    private final emptyLabel:Label;
    private final pager:Null<Pager>;

    private var narrow:Null<Bool> = null;
    private var columns:Int = 0;
    private var pageSize:Int = 0;
    private var cardWidth:Float = 0;
    private var page:Int = 1;
    private var loaded:Bool = false;
    private var allGames:Array<GameRecord> = [];
    private var games:Array<GameRecord> = [];
    private var cards:Array<GameCard> = [];

    public function new(kind:GamesSectionKind, callbacks:GamesSectionCallbacks)
    {
        super();
        this.kind = kind;
        this.callbacks = callbacks;
        filter = new GameListFilter(kind == Ongoing);
        percentWidth = 100;
        addClass(StyleClass.HOME_CARD);
        addClass(StyleClass.HOME_GAMES_SECTION);

        heading = new HBox();
        heading.percentWidth = 100;
        heading.addClass(StyleClass.HOME_GAMES_HEADING);
        addComponent(heading);

        titleLabel = new Label();
        titleLabel.text = LocaleUtils.localeBinding(titleKey(kind));
        titleLabel.addClass(StyleClass.HOME_GAMES_TITLE);
        titleLabel.verticalAlign = "center";

        headingSpacer = new Box();
        headingSpacer.percentWidth = 100;

        var ownTab:Int = kind == Ongoing ? 0 : 1;
        tabs = new UnderlineTabs([LocaleUtils.localeBinding(titleKey(Ongoing)), LocaleUtils.localeBinding(titleKey(Recent))], true, index -> {
            tabs.selectedIndex = ownTab; // the other section shows instead, with its own tab selected
            callbacks.onTabSelected(index);
        });
        tabs.selectedIndex = ownTab;

        pillButton = new Button();
        pillButton.addClass(StyleClass.HOME_PILL);
        pillButton.verticalAlign = "center";
        pillButton.hidden = true;
        pillButton.onClick = _ -> render();

        filterRow = new HBox();
        filterRow.percentWidth = 100;
        filterRow.continuous = true;
        filterRow.addClass(StyleClass.HOME_FILTER_ROW);
        addComponent(filterRow);

        kindFilter = new FilterDropdown(
            LocaleUtils.localeBinding("intellector.common.filter.time_control"),
            [for (kind in KINDS) {caption: LocaleUtils.localeBinding('intellector.common.time_control_kind.${kind.getName().toLowerCase()}'), kind: kind}],
            true,
            250,
            selection -> {
                filter.kinds = [for (i in selection) KINDS[i]];
                onFilterChanged();
            },
            LocaleUtils.localeBinding("intellector.common.filter.any_hint"),
            kind == Ongoing ? LocaleUtils.localeBinding("intellector.common.filter.live") : null
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
                filter.rated = TYPE_RATED[selection[0]];
                onFilterChanged();
            }
        );
        filterRow.addComponent(typeFilter);

        resetButton = new Button();
        resetButton.text = LocaleUtils.localeBinding("intellector.common.filter.reset");
        resetButton.addClass(StyleClass.FILTER_RESET);
        resetButton.onClick = _ -> {
            filter.reset();
            onFilterChanged();
        };
        filterRow.addComponent(resetButton);


        panel = new Box();
        panel.percentWidth = 100;
        panel.addClass(StyleClass.HOME_GAMES_PANEL);
        addComponent(panel);

        grid = new VBox();
        grid.percentWidth = 100;
        grid.addClass(StyleClass.HOME_GAMES_GRID);
        panel.addComponent(grid);

        loadStatus = new LoadStatus();
        loadStatus.verticalAlign = "center";
        panel.addComponent(loadStatus);

        emptyLabel = new Label();
        emptyLabel.addClass(StyleClass.GAME_RECORD_MUTED);
        emptyLabel.horizontalAlign = "center";
        emptyLabel.verticalAlign = "center";
        emptyLabel.hidden = true;
        panel.addComponent(emptyLabel);

        if (kind == Ongoing)
        {
            pager = new Pager(target -> {
                page = Std.int(Math.max(1, target));
                render();
            });
            addComponent(pager);
        }
        else
            pager = null;

        renderFilter();
        setNarrow(false);
    }

    /** Replaces the whole list: the feed has just delivered its state **/
    public function setGames(games:Array<GameRecord>):Void
    {
        allGames = games;
        loaded = true;
        onGamesChanged();
    }

    /** The newest game goes first; Recent drops the oldest one if the list is full **/
    public function addGame(game:GameRecord):Void
    {
        allGames = allGames.filter(other -> other.id != game.id);
        allGames.unshift(game);
        if (kind == Recent && allGames.length > RECENT_SIZE)
            allGames.resize(RECENT_SIZE);
        onGamesChanged();
    }

    public function removeGame(id:Int):Void
    {
        var remaining:Array<GameRecord> = allGames.filter(game -> game.id != id);
        if (remaining.length == allGames.length)
            return;
        allGames = remaining;
        onGamesChanged();
    }

    public function showLoading():Void
    {
        grid.removeAllComponents();
        cards = [];
        emptyLabel.hidden = true;
        loadStatus.showLoading();
        loadStatus.hidden = false;
    }

    public function setNarrow(narrow:Bool):Void
    {
        if (narrow == this.narrow)
            return;
        this.narrow = narrow;

        for (part in [titleLabel, tabs, headingSpacer, pillButton])
            if (part.parentComponent != null)
                part.parentComponent.removeComponent(part, false);

        heading.setClass(StyleClass.HOME_NARROW, narrow);
        if (narrow)
        {
            heading.addComponent(tabs);
            filterRow.addComponent(pillButton);
            filterRow.height = NARROW_FILTER_ROW_HEIGHT;
        }
        else
        {
            heading.addComponent(titleLabel);
            heading.addComponent(headingSpacer);
            heading.addComponent(pillButton);
            filterRow.height = null;
            filterRow.invalidateComponentLayout();
        }
    }

    /** `width`: the page's content width, which the column count follows **/
    public function setContentWidth(width:Float):Void
    {
        var newColumns:Int = width >= THREE_COLUMNS_MIN_WIDTH ? 3 : width >= TWO_COLUMNS_MIN_WIDTH ? 2 : 1;
        var innerWidth:Float = width - SECTION_BORDERS_WIDTH - 2 * PANEL_PADDING;
        var newCardWidth:Float = (innerWidth - CARD_GAP * (newColumns - 1)) / newColumns;
        var cardWidthChanged:Bool = (newCardWidth < GameCard.COMPACT_MAX_WIDTH) != (cardWidth < GameCard.COMPACT_MAX_WIDTH);
        cardWidth = newCardWidth;
        if (newColumns == columns)
        {
            if (cardWidthChanged)
                applyBoardWidth();
            return;
        }

        var firstIndex:Int = (page - 1) * pageSize;
        columns = newColumns;
        var rows:Int = rowCount();
        pageSize = kind == Ongoing ? columns * rows : RECENT_SIZE;
        panel.height = 2 * PANEL_PADDING + GameCard.HEIGHT * rows + CARD_GAP * (rows - 1);

        page = Std.int(firstIndex / pageSize) + 1;
        render();
    }

    public function showFailure(timedOut:Bool):Void
    {
        grid.removeAllComponents();
        cards = [];
        emptyLabel.hidden = true;
        loadStatus.showFailure(timedOut, callbacks.onRetry);
        loadStatus.hidden = false;
    }

    /** Refreshes the time since each ongoing correspondence game's last move **/
    public function refreshTimes():Void
    {
        if (kind == Ongoing)
            for (card in cards)
                if (card.game.timeControl.match(None))
                    setCardStatus(card);
    }

    public function dispose():Void
    {
        kindFilter.close();
        typeFilter.close();
    }

    private function rowCount():Int
    {
        return switch kind {
            case Ongoing: columns == 1 ? 3 : 2;
            case Recent: Std.int(RECENT_SIZE / columns);
        }
    }

    private function pageCountOf(total:Int):Int
    {
        return Std.int(Math.max(1, Math.ceil(total / pageSize)));
    }

    private function onFilterChanged():Void
    {
        page = 1;
        renderFilter();
        if (kind == Recent)
            callbacks.onFilterChanged(filter);
        else
            render();
    }

    /** Ongoing past its first page stays as it is, so that the page doesn't shift under the reader **/
    private function onGamesChanged():Void
    {
        if (kind == Ongoing && page > 1 && cards.length > 0)
            setPill(LocaleUtils.localeBinding("intellector.home.games.updated"));
        else
            render();
    }

    /** `text`, a locale binding, says the shown page is behind the games; null hides the pill **/
    private function setPill(text:Null<String>):Void
    {
        pillButton.hidden = text == null;
        if (text != null)
            pillButton.text = text;
    }

    private function render():Void
    {
        if (pageSize == 0 || !loaded)
            return;

        var matching:Array<GameRecord> = kind == Ongoing ? allGames.filter(game -> filter.matches(game.timeControl.getKind(), game.rated)) : allGames;
        page = Std.int(Math.min(page, pageCountOf(matching.length)));
        games = kind == Ongoing ? matching.slice((page - 1) * pageSize, page * pageSize) : matching;

        if (kind == Ongoing)
        {
            var counts:GameCounts = filter.countsOf(allGames);
            kindFilter.setCounts([for (kind in KINDS) counts.ofKind(kind)]);
            typeFilter.setCounts([counts.rated + counts.casual, counts.rated, counts.casual]);
            renderPager(matching.length);
        }

        setPill(null);
        loadStatus.hidden = true;
        renderCards();
        emptyLabel.hidden = games.length > 0;
        emptyLabel.text = LocaleUtils.localeBinding(!filter.isDefault() ? "intellector.home.games.no_match" : kind == Ongoing ? "intellector.home.games.no_ongoing" : "intellector.home.games.no_recent");
    }

    private function renderFilter():Void
    {
        kindFilter.setSelection([for (i in 0...KINDS.length) if (filter.kinds.contains(KINDS[i])) i]);
        typeFilter.setSelection([TYPE_RATED.indexOf(filter.rated)]);
        resetButton.disabled = filter.isDefault();
    }

    private function renderPager(total:Int):Void
    {
        var first:Int = (page - 1) * pageSize + 1;
        pager.setState(page, pageCountOf(total), first, Std.int(Math.min(page * pageSize, total)), total);
    }

    private function renderCards():Void
    {
        grid.removeAllComponents();
        cards = [];

        var row:Null<HBox> = null;
        for (i in 0...games.length)
        {
            if (i % columns == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.HOME_GAMES_ROW);
                grid.addComponent(row);
            }

            var game:GameRecord = games[i];
            var card:GameCard = new GameCard(game, White);
            if (kind == Recent)
                card.setGame(game, winnerOf(game.ending));
            setCardStatus(card);
            cards.push(card);
            row.addComponent(card);
        }

        if (row != null && games.length % columns != 0)
            for (_ in 0...columns - games.length % columns)
            {
                var filler:Box = new Box();
                filler.percentWidth = 100;
                row.addComponent(filler);
            }

        applyBoardWidth();
    }

    private function applyBoardWidth():Void
    {
        var boardWidth:Float = cardWidth < GameCard.COMPACT_MAX_WIDTH ? GameCard.COMPACT_BOARD_WIDTH : GameCard.BOARD_WIDTH;
        for (card in cards)
            card.setBoardWidth(boardWidth);
    }

    private function setCardStatus(card:GameCard):Void
    {
        var game:GameRecord = card.game;
        var ending:Null<GameEnding> = game.ending;
        if (ending != null)
            card.setStatus(() -> GameFormatters.result(ending), () -> GameFormatters.outcomeReason(ending));
        else if (!game.timeControl.match(None))
            card.setStatus(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.common.outcome.result.in_progress")), () -> "");
        else
        {
            var turnKey:String = 'intellector.common.turn_color.${game.position.turnColor.getName().toLowerCase()}';
            var waitedMs:Null<Float> = OngoingGameFormatters.elapsedSince(game.waitingSinceMs(), ServerTime.now());
            card.setStatus(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding(turnKey)), () -> OngoingGameFormatters.lastMoveAgoText(waitedMs));
        }
    }

    private static function winnerOf(ending:Null<GameEnding>):Null<PieceColor>
    {
        if (ending == null)
            return null;
        return switch ending.outcome {
            case Decisive(_, winner): winner;
            case Drawish(_): null;
        }
    }

    private static function titleKey(kind:GamesSectionKind):String
    {
        return switch kind {
            case Ongoing: "intellector.home.games.ongoing";
            case Recent: "intellector.home.games.recent";
        }
    }
}
