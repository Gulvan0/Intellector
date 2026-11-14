package client.ui.games;

import client.datatypes.game.GameParticipant;
import client.datatypes.games.ArchiveGame;
import client.datatypes.games.ResultColumn;
import client.datatypes.games.SortLevel;
import client.formatters.ArchiveFormatters;
import client.formatters.GameFormatters;
import client.logic.games.ResultColumns;
import client.logic.games.SortRules;
import client.ui.common.TimeControlKindIcon;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.StyleElement;

using client.ui.ComponentExtension;

/**
    A page of results, one column per visible result column, scrolling sideways in the browser's own
    scroller when wider than the card. Headers sort; cell texts are selectable.
**/
class ResultsTable extends Box
{
    private static inline final DASH:String = "—";
    private static inline final SELECTABLE_CLASS:String = "intellector-selectable-text";
    private static inline final HEADER_HEIGHT:Int = 37;
    private static inline final ROW_HEIGHT:Int = 40;
    private static inline final HEADER_COLOR:String = "#f0ebe2";
    private static inline final LINE_COLOR:String = "#e6dfd3";

    private static var styleInjected:Bool = false;

    private final grid:HBox;

    /** A header pressed **/
    public var onHeaderClicked:ResultColumn->Void = _ -> {};

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAMES_TABLE_SCROLLER);
        var style:CSSStyleDeclaration = element.style;
        style.overflowX = "auto";
        style.overflowY = "hidden";

        injectStyleOnce();

        grid = new HBox();
        grid.addClass(StyleClass.GAMES_TABLE);
        drawRowLines(grid.element.style);
        addComponent(grid);
    }

    public function render(games:Array<ArchiveGame>, columns:Array<ResultColumn>, sort:Array<SortLevel>):Void
    {
        grid.removeAllComponents();
        for (column in ResultColumns.ordered(columns))
        {
            var columnBox:VBox = new VBox();
            columnBox.addClass(StyleClass.GAMES_TABLE_COLUMN);
            columnBox.addComponent(header(column, sort));
            for (game in games)
            {
                var cell:Box = new Box();
                cell.addClass(StyleClass.GAMES_TABLE_CELL);
                cell.addComponent(cellContent(game, column));
                columnBox.addComponent(cell);
            }
            grid.addComponent(columnBox);
        }
    }

    /*
        Columns size to their widest cell, so cells differ in width within a column: the header band
        and the row separators are painted across the whole grid instead
    */
    private static function drawRowLines(style:CSSStyleDeclaration):Void
    {
        var header:String = 'linear-gradient(to bottom, $HEADER_COLOR 0 ${HEADER_HEIGHT - 1}px, $LINE_COLOR ${HEADER_HEIGHT - 1}px $HEADER_HEIGHT' + 'px) 0 0 / 100% ${HEADER_HEIGHT}px no-repeat';
        var rows:String = 'repeating-linear-gradient(to bottom, transparent 0 ${ROW_HEIGHT - 1}px, $LINE_COLOR ${ROW_HEIGHT - 1}px ${ROW_HEIGHT}px) 0 ${HEADER_HEIGHT}px / 100% 100% no-repeat';
        style.background = '$header, $rows';
    }

    private function header(column:ResultColumn, sort:Array<SortLevel>):HBox
    {
        var header:HBox = new HBox();
        header.addClass(StyleClass.GAMES_TABLE_HEADER);

        var level:Null<Int> = SortRules.levelOf(sort, column);
        header.setClass(StyleClass.GAMES_TABLE_HEADER_SORTED, level != null);

        var nameLabel:Label = new Label();
        LocaleManager.instance.registerComponent(nameLabel, "text", () -> ArchiveFormatters.columnName(column));
        nameLabel.addClass(StyleClass.GAMES_TABLE_HEADER_TEXT);
        nameLabel.verticalAlign = "center";
        header.addComponent(nameLabel);

        if (!ResultColumns.isSortable(column))
            return header;

        header.trackHover();
        header.registerEvent(MouseEvent.CLICK, _ -> onHeaderClicked(column));

        var indicator:Label = new Label();
        indicator.verticalAlign = "center";
        if (level != null)
        {
            var arrow:String = sort[level].descending ? "↓" : "↑";
            indicator.text = sort.length > 1 ? '$arrow${level + 1}' : arrow;
            indicator.addClass(StyleClass.GAMES_TABLE_LEVEL);
        }
        else
        {
            indicator.text = "↑";
            indicator.addClass(StyleClass.GAMES_TABLE_LEVEL_GHOST);
        }
        header.addComponent(indicator);
        return header;
    }

    private function cellContent(game:ArchiveGame, column:ResultColumn):Component
    {
        return switch column {
            case ID: textCell(Std.string(game.id), true);
            case LINK: link(game.id);
            case WHITE: participant(game.white);
            case BLACK: participant(game.black);
            case WHITE_ELO: textCell(rating(game.rated, game.white), true);
            case BLACK_ELO: textCell(rating(game.rated, game.black), true);
            case STARTED_AT: textCell(GameFormatters.optionalDateTime(game.startedAtMs), true);
            case ENDED_AT: textCell(game.outcome == null ? DASH : GameFormatters.optionalDateTime(game.endedAtMs), true);
            case DURATION: textCell(game.durationMs != null ? ArchiveFormatters.gameDuration(game.durationMs) : DASH, true);
            case TIME_CONTROL: timeControl(game);
            case START_TIME: textCell(game.startSeconds != null ? ArchiveFormatters.clock(game.startSeconds * 1000.0) : DASH, true);
            case BONUS_TIME: textCell(game.incrementSeconds != null ? ArchiveFormatters.clock(game.incrementSeconds * 1000.0) : DASH, true);
            case RATED: localizedCell(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding(game.rated ? "intellector.games.value.yes" : "intellector.games.value.no")));
            case STARTING_POSITION: game.customStartingSip != null ? textCell(game.customStartingSip, true) : localizedCell(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.value.default_position")));
            case RESULT: localizedCell(() -> ArchiveFormatters.result(game.outcome));
            case OUTCOME: localizedCell(() -> ArchiveFormatters.outcome(game.outcome) ?? DASH, true);
            case OPENING: textCell(game.openingId != null ? ArchiveFormatters.openingName(game.openingId) : DASH, false);
            case MOVE_COUNT: textCell(Std.string(game.moveCount), true);
            case TIME_LEFT_WHITE: textCell(clockOrDash(game.whiteTimeLeftMs), true);
            case TIME_LEFT_BLACK: textCell(clockOrDash(game.blackTimeLeftMs), true);
        }
    }

    private function textCell(content:String, mono:Bool):Label
    {
        var label:Label = createCellLabel(mono ? StyleClass.GAMES_TABLE_MONO : StyleClass.GAMES_TABLE_TEXT);
        label.text = content;
        return label;
    }

    private function localizedCell(content:Void->String, dim:Bool = false):Label
    {
        var label:Label = createCellLabel(dim ? StyleClass.GAMES_TABLE_DIM : StyleClass.GAMES_TABLE_TEXT);
        LocaleManager.instance.registerComponent(label, "text", content);
        return label;
    }

    private function participant(participant:GameParticipant):Label
    {
        var label:Label = createCellLabel(StyleClass.GAMES_TABLE_TEXT);
        label.text = participant.nickname;
        return label;
    }

    private function link(gameId:Int):Box
    {
        var path:String = PagePaths.liveGame(gameId);
        var box:Box = new Box();
        box.verticalAlign = "center";
        var label:Label = new Label();
        label.text = HaxeFolioApp.pageUrl(path);
        label.addClass(StyleClass.GAMES_TABLE_LINK);
        box.addComponent(label);
        PageLink.attach(box, path);
        return box;
    }

    private function timeControl(game:ArchiveGame):HBox
    {
        var box:HBox = new HBox();
        box.addClass(StyleClass.GAMES_TABLE_TIME_CONTROL);
        box.verticalAlign = "center";
        box.addComponent(new TimeControlKindIcon(game.timeControlKind, 14));
        var kindKey:String = 'intellector.common.time_control_kind.${game.timeControlKind.getName().toLowerCase()}';
        var label:Label = createCellLabel(StyleClass.GAMES_TABLE_TEXT);
        label.text = LocaleUtils.localeBinding(kindKey);
        box.addComponent(label);
        return box;
    }

    private function createCellLabel(styleClass:StyleClass):Label
    {
        var label:Label = new Label();
        label.addClass(styleClass);
        label.verticalAlign = "center";
        label.element.classList.add(SELECTABLE_CLASS);
        return label;
    }

    // HaxeUI makes all text unselectable, and rewrites the inline styles of a label's text
    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;
        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '#haxeui-container .haxeui-component.$SELECTABLE_CLASS, #haxeui-container .haxeui-component.$SELECTABLE_CLASS * { user-select: text; -webkit-user-select: text; cursor: text; }';
        Browser.document.head.appendChild(style);
    }

    private static function rating(rated:Bool, participant:GameParticipant):String
    {
        return rated && participant.rating != null ? GameFormatters.bareRating(participant.rating) : DASH;
    }

    private static function clockOrDash(ms:Null<Float>):String
    {
        return ms != null ? ArchiveFormatters.clock(ms) : DASH;
    }
}
