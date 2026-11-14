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
import haxe.ui.components.Button;
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
import haxefolio.structure.SidewaysFade;
import js.Browser;
import js.html.CSSStyleDeclaration;
import js.html.ClipboardEvent;
import js.html.Element;
import js.html.Selection;
import js.html.StyleElement;

using client.ui.ComponentExtension;

/**
    A page of results, one column per visible result column, scrolling sideways in the browser's own
    scroller when wider than the card. Headers sort; cell texts are selectable with a mouse, while a
    finger pans the table.
**/
class ResultsTable extends Box
{
    private static inline final DASH:String = "—";
    private static inline final SELECTABLE_CLASS:String = "intellector-selectable-text";
    private static inline final SCROLLER_CLASS:String = "intellector-games-table-scroll";
    /** Marks the labels whose texts make up a cell's copied text **/
    private static inline final CELL_TEXT_CLASS:String = "intellector-games-cell-text";
    private static inline final HEADER_HEIGHT:Int = 37;
    private static inline final SCROLLBAR_LANE:Int = 10;
    private static inline final SCROLLBAR_INSET:Int = 10;
    private static inline final ROW_HEIGHT:Int = 40;
    private static inline final HEADER_COLOR:String = "#f0ebe2";
    private static inline final LINE_COLOR:String = "#e6dfd3";

    private static var styleInjected:Bool = false;

    private final grid:HBox;
    /** Room under the grid for the native scrollbar, which would otherwise cover the last row **/
    private final scrollbarLane:Box;
    private final preview:SipPreview = new SipPreview();
    /** The header row, then the game rows, as last rendered **/
    private var rowCells:Array<Array<Element>> = [];

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
        element.classList.add(SCROLLER_CLASS);

        injectStyleOnce();

        var content:VBox = new VBox();
        content.addClass(StyleClass.GAMES_TABLE_CONTENT);
        addComponent(content);

        grid = new HBox();
        grid.addClass(StyleClass.GAMES_TABLE);
        drawRowLines(grid.element.style);
        content.addComponent(grid);

        scrollbarLane = new Box();
        scrollbarLane.height = SCROLLBAR_LANE;
        scrollbarLane.hidden = true;
        content.addComponent(scrollbarLane);

        SidewaysFade.attach(element);
        var observer:Dynamic = js.Syntax.code("new ResizeObserver({0})", (_:Array<Dynamic>) -> reserveScrollbarLane());
        observer.observe(element);
        observer.observe(grid.element);
        Browser.document.addEventListener("copy", onCopy);
    }

    public function render(games:Array<ArchiveGame>, columns:Array<ResultColumn>, sort:Array<SortLevel>):Void
    {
        preview.close();
        grid.removeAllComponents();
        rowCells = [for (_ in 0...games.length + 1) []];
        for (column in ResultColumns.ordered(columns))
        {
            var columnBox:VBox = new VBox();
            columnBox.addClass(StyleClass.GAMES_TABLE_COLUMN);
            var headerBox:HBox = header(column, sort);
            columnBox.addComponent(headerBox);
            rowCells[0].push(headerBox.element);
            for (i in 0...games.length)
            {
                var cell:Box = new Box();
                cell.addClass(StyleClass.GAMES_TABLE_CELL);
                cell.addComponent(cellContent(games[i], column));
                columnBox.addComponent(cell);
                rowCells[i + 1].push(cell.element);
            }
            grid.addComponent(columnBox);
        }
    }

    public function closePreview():Void
    {
        preview.close();
    }

    private override function onDestroy():Void
    {
        preview.close();
        Browser.document.removeEventListener("copy", onCopy);
        super.onDestroy();
    }

    private function reserveScrollbarLane():Void
    {
        var scrollable:Bool = SidewaysFade.isScrollable(element);
        if (scrollbarLane.hidden == scrollable)
            scrollbarLane.hidden = !scrollable;
    }

    /*
        The cells are laid out column by column, so the browser would copy a selection column-first:
        the selected cells are copied row by row instead, tab-separated, a cell outside the selection
        left blank. A selection within a single cell is copied as usual.
    */
    private function onCopy(event:ClipboardEvent):Void
    {
        var selection:Null<Selection> = Browser.window.getSelection();
        if (selection == null || selection.isCollapsed || !selection.containsNode(grid.element, true))
            return;

        var selectedRows:Array<Int> = [];
        var selectedColumns:Array<Int> = [];
        for (row in 0...rowCells.length)
            for (column in 0...rowCells[row].length)
                if (selection.containsNode(rowCells[row][column], true))
                {
                    if (!selectedRows.contains(row))
                        selectedRows.push(row);
                    if (!selectedColumns.contains(column))
                        selectedColumns.push(column);
                }

        if (selectedRows.length * selectedColumns.length <= 1)
            return;

        selectedColumns.sort((a, b) -> a - b);
        var lines:Array<String> = [
            for (row in selectedRows)
                [for (column in selectedColumns) selection.containsNode(rowCells[row][column], true) ? cellText(rowCells[row][column]) : ""].join("\t")
        ];
        event.clipboardData.setData("text/plain", lines.join("\n"));
        event.preventDefault();
    }

    private static function cellText(cell:Element):String
    {
        return [for (label in cell.querySelectorAll('.$CELL_TEXT_CLASS')) StringTools.trim(label.textContent)].join(" ");
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
        nameLabel.element.classList.add(CELL_TEXT_CLASS);
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
            case DURATION: textCell(durationOrDash(game.durationMs), true);
            case TIME_CONTROL: timeControl(game);
            case START_TIME: textCell(game.startSeconds != null ? ArchiveFormatters.clock(game.startSeconds * 1000.0) : DASH, true);
            case BONUS_TIME: textCell(game.incrementSeconds != null ? ArchiveFormatters.clock(game.incrementSeconds * 1000.0) : DASH, true);
            case RATED: localizedCell(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding(game.rated ? "intellector.games.value.yes" : "intellector.games.value.no")));
            case STARTING_POSITION: game.customStartingSip != null ? customPosition(game.customStartingSip) : localizedCell(() -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.value.default_position")));
            case RESULT: localizedCell(() -> ArchiveFormatters.result(game.outcome));
            case OUTCOME: localizedCell(() -> ArchiveFormatters.outcome(game.outcome) ?? DASH, true);
            case OPENING: textCell(game.openingId != null ? ArchiveFormatters.openingName(game.openingId) : DASH, false);
            case MOVE_COUNT: textCell(Std.string(game.moveCount), true);
            case TIME_LEFT_WHITE: textCell(durationOrDash(game.whiteTimeLeftMs), true);
            case TIME_LEFT_BLACK: textCell(durationOrDash(game.blackTimeLeftMs), true);
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
        label.element.classList.add(CELL_TEXT_CLASS);
        box.addComponent(label);
        PageLink.attach(box, path);
        return box;
    }

    private function customPosition(sip:String):HBox
    {
        var box:HBox = new HBox();
        box.addClass(StyleClass.GAMES_TABLE_POSITION);
        box.verticalAlign = "center";
        box.addComponent(textCell(sip, true));
        var toggle:Null<Button> = preview.createToggle(sip);
        if (toggle != null)
            box.addComponent(toggle);
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
        label.element.classList.add(CELL_TEXT_CLASS);
        return label;
    }

    /*
        HaxeUI makes all text unselectable and rewrites the inline styles of a label's text. Cell texts
        are made selectable with a mouse only: a finger dragging over the table pans it both ways,
        where the page's scroll area would only let it pan vertically.
    */
    private static function injectStyleOnce():Void
    {
        if (styleInjected)
            return;

        styleInjected = true;
        var style:StyleElement = Browser.document.createStyleElement();
        style.textContent = '
            #haxeui-container .$SCROLLER_CLASS.$SCROLLER_CLASS, #haxeui-container .$SCROLLER_CLASS.$SCROLLER_CLASS .haxeui-component { touch-action: pan-x pan-y; }
            @media not (pointer: coarse) {
                #haxeui-container .haxeui-component.$SELECTABLE_CLASS, #haxeui-container .haxeui-component.$SELECTABLE_CLASS * { user-select: text; -webkit-user-select: text; cursor: text; }
                .$SCROLLER_CLASS::-webkit-scrollbar { height: ${SCROLLBAR_LANE}px; background: transparent; }
                .$SCROLLER_CLASS::-webkit-scrollbar-track { background: transparent; margin: 0 ${SCROLLBAR_INSET}px; }
                .$SCROLLER_CLASS::-webkit-scrollbar-thumb { background-color: #cccdd1; background-clip: padding-box; border: 2px solid transparent; border-radius: 6px; }
                .$SCROLLER_CLASS::-webkit-scrollbar-thumb:hover { background-color: #b3b3b6; }
                .$SCROLLER_CLASS::-webkit-scrollbar-thumb:active { background-color: #90929a; }
                @supports not selector(::-webkit-scrollbar) { .$SCROLLER_CLASS { scrollbar-width: thin; scrollbar-color: #cccdd1 transparent; } }
            }
        ';
        Browser.document.head.appendChild(style);
    }

    private static function rating(rated:Bool, participant:GameParticipant):String
    {
        return rated && participant.rating != null ? GameFormatters.bareRating(participant.rating) : DASH;
    }

    private static function durationOrDash(ms:Null<Float>):String
    {
        return ms != null ? ArchiveFormatters.duration(ms) : DASH;
    }
}
