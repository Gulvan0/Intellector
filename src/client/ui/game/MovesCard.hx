package client.ui.game;

import client.datatypes.game.PlyNavigationType;
import client.formatters.GameFormatters;
import client.openings.OpeningEntry;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/**
    The move list, two plies a row (White's, then Black's), with the navigation buttons. The opening
    line under the title is hidden until shown with `setOpeningShown`.
**/
class MovesCard extends VBox
{
    private final header:VBox;
    private final titleLabel:Label;
    private final openingLabel:Label;
    private final progressLabel:Label;
    private final navigationRow:HBox;
    private final navigationButtons:Map<PlyNavigationType, Button> = [];
    private final rowList:VBox;
    private final scrollArea:ScrollArea;
    private final onNavigate:PlyNavigationType->Void;

    // cells[i]: the cell of ply i
    private var cells:Array<HBox> = [];
    private var rows:Array<HBox> = [];
    private var notations:Array<String> = [];
    private var firstMover:Null<PieceColor> = null;
    private var shownPlyCount:Int = 0;
    private var plyCount:Int = 0;
    private var locked:Bool = false;
    private var openingShown:Bool = false;
    private var openingText:Null<Void->String> = null;

    public function new(onNavigate:PlyNavigationType->Void)
    {
        super();
        this.onNavigate = onNavigate;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_MOVES_CARD);

        header = new VBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.GAME_MOVES_HEADER);
        addComponent(header);

        var titleRow:HBox = new HBox();
        titleRow.percentWidth = 100;
        header.addComponent(titleRow);

        var titles:VBox = new VBox();
        titles.percentWidth = 100;
        titles.verticalAlign = "center";
        titles.addClass(StyleClass.GAME_TIGHT_STACK);
        titleRow.addComponent(titles);

        titleLabel = new Label();
        titleLabel.text = LocaleUtils.localeBinding("intellector.live_game.moves.title");
        titleLabel.addClass(StyleClass.GAME_CARD_TITLE);
        titles.addComponent(titleLabel);

        openingLabel = new Label();
        openingLabel.percentWidth = 100;
        openingLabel.addClass(StyleClass.GAME_OPENING);
        titles.addComponent(openingLabel);

        progressLabel = new Label();
        progressLabel.addClass(StyleClass.GAME_HINT);
        progressLabel.verticalAlign = "center";
        titleRow.addComponent(progressLabel);

        navigationRow = new HBox();
        navigationRow.percentWidth = 100;
        navigationRow.addClass(StyleClass.GAME_NAVIGATION_ROW);
        header.addComponent(navigationRow);

        for (type in [Start, Previous, Next, End])
        {
            var button:Button = GameButtons.navigation(type, onNavigate);
            button.percentWidth = 25;
            navigationButtons.set(type, button);
            navigationRow.addComponent(button);
        }

        rowList = new VBox();
        rowList.percentWidth = 100;
        rowList.addClass(StyleClass.GAME_MOVES_TABLE);

        scrollArea = new ScrollArea(rowList);
        scrollArea.percentHeight = 100;
        scrollArea.addClass(StyleClass.GAME_MOVES_SCROLL);
        addComponent(scrollArea);

        setShown(0, 0);
        refreshOpening();
    }

    /**
        `notations[i]`: ply i's notation; `firstMover`: whoever plays ply 0. Rebuilds only the rows
        from the first ply that differs from the previous call's.
    **/
    public function setMoves(notations:Array<String>, firstMover:PieceColor):Void
    {
        var offset:Int = firstMover == White ? 0 : 1; // Black's first ply takes a row's second slot
        var keptPlyCount:Int = firstMover == this.firstMover ? commonPrefixLength(this.notations, notations) : 0;
        var keptRowCount:Int = Std.int((keptPlyCount + offset) / 2);
        while (rows.length > keptRowCount)
            rowList.removeComponent(rows.pop());

        var firstRebuiltPly:Int = Std.int(Math.max(0, keptRowCount * 2 - offset));
        cells = cells.slice(0, firstRebuiltPly);
        this.notations = notations.copy();
        this.firstMover = firstMover;

        var row:Null<HBox> = null;
        for (i in firstRebuiltPly...notations.length)
        {
            var slot:Int = (i + offset) % 2;
            if (row == null || slot == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.GAME_MOVES_ROW);
                rows.push(row);
                rowList.addComponent(row);
                if (slot == 1)
                    row.addComponent(createEmptyCell());
            }

            var cell:HBox = createCell(i, notations[i]);
            cells.push(cell);
            row.addComponent(cell);
        }

        highlightShown();
    }

    /** Compact pages navigate with the move strip instead **/
    public function setNavigationShown(shown:Bool):Void
    {
        navigationRow.hidden = !shown;
    }

    /** Hidden while a tab names the card **/
    public function setTitleShown(shown:Bool):Void
    {
        titleLabel.hidden = !shown;
    }

    /** Hidden, the card is reduced to whatever is added above its content, such as tabs **/
    public function setContentShown(shown:Bool):Void
    {
        header.hidden = !shown;
        scrollArea.hidden = !shown;
    }

    public function setOpeningShown(shown:Bool):Void
    {
        openingShown = shown;
        refreshOpening();
    }

    /** `customStartingPosition`: the game didn't start from the default position, so it has no opening **/
    public function setOpening(opening:Null<OpeningEntry>, customStartingPosition:Bool):Void
    {
        openingText = GameFormatters.opening(opening, customStartingPosition);
        refreshOpening();
    }

    /** `shownPlyCount` plies of `plyCount` are shown **/
    public function setShown(shownPlyCount:Int, plyCount:Int):Void
    {
        this.shownPlyCount = shownPlyCount;
        this.plyCount = plyCount;
        progressLabel.text = shownPlyCount == 0
            ? LocaleUtils.localeBinding("intellector.live_game.moves.start")
            : LocaleUtils.localeBinding("intellector.live_game.moves.progress", Std.string(shownPlyCount), Std.string(plyCount));

        navigationButtons.get(Start).disabled = locked || shownPlyCount == 0;
        navigationButtons.get(Previous).disabled = locked || shownPlyCount == 0;
        navigationButtons.get(Next).disabled = locked || shownPlyCount == plyCount;
        navigationButtons.get(End).disabled = locked || shownPlyCount == plyCount;

        highlightShown();
    }

    /** Disabled in place: navigation off, the moves greyed out **/
    public function setLocked(locked:Bool):Void
    {
        this.locked = locked;
        this.setClass(StyleClass.ANALYSIS_LOCKED, locked);
        invalidateComponentStyle(true, true); // descendant selectors depend on it
        setShown(shownPlyCount, plyCount);
    }

    private function refreshOpening():Void
    {
        openingLabel.hidden = !openingShown || openingText == null;
        if (openingText != null)
            LocaleManager.instance.registerComponent(openingLabel, "text", openingText);
    }

    private function highlightShown():Void
    {
        for (i in 0...cells.length)
            cells[i].setClass(StyleClass.GAME_MOVE_CELL_CURRENT, i == shownPlyCount - 1);

        if (shownPlyCount > 0 && shownPlyCount <= cells.length)
            scrollIntoView(cells[shownPlyCount - 1]);
    }

    // the scroll area scrolls natively, which HaxeUI's ensureVisible doesn't support
    private function scrollIntoView(cell:HBox):Void
    {
        Toolkit.callLater(() -> {
            var viewport:js.html.Element = scrollArea.element;
            var viewportRect:js.html.DOMRect = viewport.getBoundingClientRect();
            var cellRect:js.html.DOMRect = cell.element.getBoundingClientRect();
            if (cellRect.top < viewportRect.top)
                viewport.scrollTop -= Math.ceil(viewportRect.top - cellRect.top);
            else if (cellRect.bottom > viewportRect.bottom)
                viewport.scrollTop += Math.ceil(cellRect.bottom - viewportRect.bottom);
        });
    }

    private function createCell(plyIndex:Int, notation:String):HBox
    {
        var cell:HBox = new HBox();
        cell.percentWidth = 50;
        cell.addClass(StyleClass.GAME_MOVE_CELL);
        cell.trackHover();
        cell.onClick = _ -> {
            if (!locked)
                onNavigate(AfterPly(plyIndex));
        };

        var numberLabel:Label = new Label();
        numberLabel.text = Std.string(plyIndex + 1);
        numberLabel.addClass(StyleClass.GAME_MOVE_NUMBER);
        numberLabel.verticalAlign = "center";
        cell.addComponent(numberLabel);

        var notationLabel:Label = new Label();
        notationLabel.text = notation;
        notationLabel.addClass(StyleClass.GAME_MOVE_NOTATION);
        notationLabel.verticalAlign = "center";
        cell.addComponent(notationLabel);

        return cell;
    }

    private static function commonPrefixLength(a:Array<String>, b:Array<String>):Int
    {
        var length:Int = 0;
        while (length < a.length && length < b.length && a[length] == b[length])
            length++;
        return length;
    }

    private function createEmptyCell():Box
    {
        var cell:Box = new Box();
        cell.percentWidth = 50;
        return cell;
    }
}
