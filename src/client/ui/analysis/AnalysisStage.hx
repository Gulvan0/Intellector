package client.ui.analysis;

import client.ui.analysis.editor.EditorToolCard;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.InteractiveBoard;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import morestd.Detachable;

/**
    The board, as large as the area allows, with an optional strip right under it. The position
    editor's tool card hangs under them. While the stage fits a height, the board either keeps its
    size when the editor opens (the card's space is reserved, split above and below while it's
    closed) or shrinks to make room for the card.
**/
class AnalysisStage extends Box
{
    private static inline final TOOL_CARD_SPACE:Float = 128; // the card plus the column's spacing above it
    private static inline final COLUMN_SPACING:Float = 8;
    // until the first fit: the board is as wide as the column, so the column can't size to its content
    private static inline final PROVISIONAL_WIDTH:Float = 400;
    private static inline final MAX_HEIGHT_TOLERANCE:Float = 2; // smaller changes are measurement noise, and refitting on them makes the layout jitter

    /** Called after each fit of the board, which can change the stage's height **/
    public var onFitted:Void->Void = () -> {};

    private final column:VBox;
    private final board:InteractiveBoard;
    private final toolCard:EditorToolCard;
    private final observer:Dynamic;
    private final coordinatesHandle:Detachable;
    private var fitsHeight:Bool = true;
    private var editing:Bool = false;
    private var toolCardReserved:Bool = true;
    private var maxHeight:Null<Float> = null;
    private var strip:Null<Component> = null;

    public function new(board:InteractiveBoard, toolCard:EditorToolCard)
    {
        super();
        this.board = board;
        this.toolCard = toolCard;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.ANALYSIS_STAGE);

        column = new VBox();
        column.addClass(StyleClass.ANALYSIS_STAGE_COLUMN);
        column.horizontalAlign = "center";
        column.verticalAlign = "center";
        column.width = PROVISIONAL_WIDTH;
        addComponent(column);

        board.percentWidth = 100;
        column.addComponent(board);

        toolCard.horizontalAlign = "center";
        column.addComponent(toolCard);

        observer = js.Syntax.code("new ResizeObserver({0})", _ -> fit());
        observer.observe(this.element);
        coordinatesHandle = Preferences.boardCoordinates.onChange(_ -> fit());
        refreshTools();
    }

    /** Whether the height given limits the board too; if not, the stage takes its content's height **/
    public function setFitsHeight(fitsHeight:Bool):Void
    {
        this.fitsHeight = fitsHeight;
        percentHeight = fitsHeight ? 100 : null;
        if (!fitsHeight)
            height = null;
        invalidateComponentLayout();
        refreshTools();
        fit();
    }

    /** Without fitting a height: the most the stage may take, the board shrinking to keep within it; null for no limit **/
    public function setMaxHeight(maxHeight:Null<Float>):Void
    {
        if (this.maxHeight == maxHeight || (this.maxHeight != null && maxHeight != null && Math.abs(this.maxHeight - maxHeight) < MAX_HEIGHT_TOLERANCE))
            return;
        this.maxHeight = maxHeight;
        fit();
    }

    /** Shown right under the board, as wide as it; null removes the current one **/
    public function setStrip(strip:Null<Component>):Void
    {
        if (this.strip == strip)
            return;

        if (this.strip != null)
        {
            observer.unobserve(this.strip.element);
            column.removeComponent(this.strip, false);
        }
        this.strip = strip;
        if (strip != null)
        {
            column.addComponentAt(strip, 1);
            observer.observe(strip.element);
        }
        fit();
    }

    /** Whether the tool card's space stays reserved while the editor is closed, so the board doesn't shrink when it opens **/
    public function setToolCardReserved(reserved:Bool):Void
    {
        toolCardReserved = reserved;
        refreshTools();
        fit();
    }

    public function setEditing(editing:Bool):Void
    {
        this.editing = editing;
        refreshTools();
        fit();
    }

    public function dispose():Void
    {
        observer.disconnect();
        coordinatesHandle.detach();
    }

    private function refreshTools():Void
    {
        toolCard.hidden = !editing;
        var reservedSpace:Float = editing || !fitsHeight || !toolCardReserved ? 0 : TOOL_CARD_SPACE / 2;
        column.paddingTop = reservedSpace;
        column.paddingBottom = reservedSpace;
    }

    // measured from the DOM, which is what the observer reports on: HaxeUI's own size may lag behind it
    private function fit():Void
    {
        var availableWidth:Float = this.element.clientWidth;
        if (availableWidth <= 0)
            return;

        toolCard.setNarrow(availableWidth < EditorToolCard.LABELLED_WIDTH);

        var columnWidth:Float = availableWidth;
        var boardMaxWidth:Null<Float> = null;
        if (fitsHeight)
        {
            var reservedHeight:Float = editing || toolCardReserved ? TOOL_CARD_SPACE : 0;
            if (strip != null)
                reservedHeight += strip.element.offsetHeight + COLUMN_SPACING;
            var aspectRatio:Float = BoardSurface.aspectRatioOf(Preferences.boardCoordinates.get());
            columnWidth = Math.min(availableWidth, (this.element.clientHeight - reservedHeight) * aspectRatio);
        }
        else if (maxHeight != null) // only the board narrows: the control row keeps the full width
        {
            var aspectRatio:Float = BoardSurface.aspectRatioOf(Preferences.boardCoordinates.get());
            var boardWidth:Float = Math.max(0, Math.floor((maxHeight - board.controlsHeight()) * aspectRatio));
            if (boardWidth < availableWidth)
                boardMaxWidth = boardWidth;
        }
        column.width = Math.max(0, Math.floor(columnWidth));
        board.setBoardMaxWidth(boardMaxWidth);
        onFitted();
    }
}
