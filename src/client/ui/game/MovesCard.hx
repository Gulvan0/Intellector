package client.ui.game;

import client.datatypes.game.PlyNavigationType;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.structure.ScrollArea;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

/** The move list, two plies a row (White's, then Black's), with the navigation buttons **/
class MovesCard extends VBox
{
    private final progressLabel:Label;
    private final navigationRow:HBox;
    private final navigationButtons:Map<PlyNavigationType, Button> = [];
    private final rowList:VBox;
    private final scrollArea:ScrollArea;
    private final onNavigate:PlyNavigationType->Void;

    // cells[i]: the cell of ply i
    private var cells:Array<HBox> = [];
    private var shownPlyCount:Int = 0;

    public function new(onNavigate:PlyNavigationType->Void)
    {
        super();
        this.onNavigate = onNavigate;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_MOVES_CARD);

        var header:VBox = new VBox();
        header.percentWidth = 100;
        header.addClass(StyleClass.GAME_MOVES_HEADER);
        addComponent(header);

        var titleRow:HBox = new HBox();
        titleRow.percentWidth = 100;
        header.addComponent(titleRow);

        var titleLabel:Label = new Label();
        titleLabel.text = LocaleUtils.localeBinding("intellector.live_game.moves.title");
        titleLabel.addClass(StyleClass.GAME_CARD_TITLE);
        titleRow.addComponent(titleLabel);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        titleRow.addComponent(spacer);

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
    }

    /** `notations[i]`: ply i's notation; `firstMover`: whoever plays ply 0 **/
    public function setMoves(notations:Array<String>, firstMover:PieceColor):Void
    {
        rowList.removeAllComponents();
        cells = [];

        var row:Null<HBox> = null;
        var slot:Int = firstMover == White ? 0 : 1;
        for (i in 0...notations.length)
        {
            if (row == null || slot == 0)
            {
                row = new HBox();
                row.percentWidth = 100;
                row.addClass(StyleClass.GAME_MOVES_ROW);
                rowList.addComponent(row);
                if (slot == 1)
                    row.addComponent(createEmptyCell());
            }

            var cell:HBox = createCell(i, notations[i]);
            cells.push(cell);
            row.addComponent(cell);
            slot = 1 - slot;
        }

        highlightShown();
    }

    /** Compact pages navigate with the move strip instead **/
    public function setNavigationShown(shown:Bool):Void
    {
        navigationRow.hidden = !shown;
    }

    /** `shownPlyCount` plies of `plyCount` are shown **/
    public function setShown(shownPlyCount:Int, plyCount:Int):Void
    {
        this.shownPlyCount = shownPlyCount;
        progressLabel.text = shownPlyCount == 0
            ? LocaleUtils.localeBinding("intellector.live_game.moves.start")
            : LocaleUtils.localeBinding("intellector.live_game.moves.progress", Std.string(shownPlyCount), Std.string(plyCount));

        navigationButtons.get(Start).disabled = shownPlyCount == 0;
        navigationButtons.get(Previous).disabled = shownPlyCount == 0;
        navigationButtons.get(Next).disabled = shownPlyCount == plyCount;
        navigationButtons.get(End).disabled = shownPlyCount == plyCount;

        highlightShown();
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
        cell.onClick = _ -> onNavigate(AfterPly(plyIndex));

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

    private function createEmptyCell():Box
    {
        var cell:Box = new Box();
        cell.percentWidth = 50;
        return cell;
    }
}
