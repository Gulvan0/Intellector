package client.ui.game;

import client.ui.common.board.BoardSurface;
import client.ui.common.board.InteractiveBoard;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import morestd.Detachable;

/**
    The board between its two player bars, under an optional header, as wide as the area allows -
    and, while it fits the height too, no taller than it; otherwise no taller than an optional
    maximum. Requests (offers, confirmations) sit over the board's top edge.
**/
class BoardStage extends Box
{
    private static inline final BAR_HEIGHT:Float = 48;
    private static inline final COLUMN_SPACING:Float = 12;
    private static inline final REQUESTS_MAX_WIDTH:Float = 440;
    private static inline final REQUESTS_INSET:Float = 10;
    // until the first fit: the board is as wide as the column, so the column can't size to its content
    private static inline final PROVISIONAL_WIDTH:Float = 400;
    private static inline final MAX_HEIGHT_TOLERANCE:Float = 2; // smaller changes are measurement noise, and refitting on them makes the layout jitter

    /** Called after each fit of the board, which can change the stage's height **/
    public var onFitted:Void->Void = () -> {};

    public final topBar:PlayerBar;
    public final bottomBar:PlayerBar;
    public final requests:VBox;

    private final column:VBox;
    private final board:InteractiveBoard;
    private final observer:Dynamic;
    private final coordinatesHandle:Detachable;
    private var fitsHeight:Bool = true;
    private var header:Null<Component> = null;
    private var maxHeight:Null<Float> = null;

    public function new(board:InteractiveBoard)
    {
        super();
        this.board = board;
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_STAGE);

        column = new VBox();
        column.addClass(StyleClass.GAME_STAGE_COLUMN);
        column.horizontalAlign = "center";
        column.verticalAlign = "center";
        column.width = PROVISIONAL_WIDTH;
        addComponent(column);

        topBar = new PlayerBar();
        topBar.addClass(StyleClass.GAME_PLAYER_BAR_TOP);
        column.addComponent(topBar);

        var boardHolder:Box = new Box();
        boardHolder.percentWidth = 100;
        column.addComponent(boardHolder);

        board.percentWidth = 100;
        boardHolder.addComponent(board);

        requests = new VBox();
        requests.addClass(StyleClass.GAME_REQUESTS);
        requests.includeInLayout = false;
        requests.top = REQUESTS_INSET;
        boardHolder.addComponent(requests);

        bottomBar = new PlayerBar();
        bottomBar.addClass(StyleClass.GAME_PLAYER_BAR_BOTTOM);
        column.addComponent(bottomBar);

        observer = js.Syntax.code("new ResizeObserver({0})", _ -> fit());
        observer.observe(this.element);
        coordinatesHandle = Preferences.boardCoordinates.onChange(_ -> fit());
    }

    /** Whether the height given limits the board too; if not, the stage takes its content's height **/
    public function setFitsHeight(fitsHeight:Bool):Void
    {
        this.fitsHeight = fitsHeight;
        percentHeight = fitsHeight ? 100 : null;
        if (!fitsHeight)
            height = null;
        invalidateComponentLayout();
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

    /** Shown above the top bar, as wide as the board; null removes the current one **/
    public function setHeader(header:Null<Component>):Void
    {
        if (this.header == header)
            return;

        if (this.header != null)
        {
            observer.unobserve(this.header.element);
            column.removeComponent(this.header, false);
        }
        this.header = header;
        if (header != null)
        {
            column.addComponentAt(header, 0);
            observer.observe(header.element);
        }
        fit();
    }

    public function dispose():Void
    {
        observer.disconnect();
        coordinatesHandle.detach();
    }

    // measured from the DOM, which is what the observer reports on: HaxeUI's own size may lag behind it
    private function fit():Void
    {
        var availableWidth:Float = this.element.clientWidth;
        if (availableWidth <= 0)
            return;

        var columnWidth:Float = availableWidth;
        var boardMaxWidth:Null<Float> = null;
        var heightLimit:Null<Float> = fitsHeight ? this.element.clientHeight : maxHeight;
        if (heightLimit != null)
        {
            var aspectRatio:Float = BoardSurface.aspectRatioOf(Preferences.boardCoordinates.get());
            var reservedHeight:Float = 2 * (BAR_HEIGHT + COLUMN_SPACING) + board.controlsHeight();
            if (header != null)
                reservedHeight += header.element.offsetHeight + COLUMN_SPACING;
            var boardWidth:Float = Math.max(0, Math.floor((heightLimit - reservedHeight) * aspectRatio));
            if (fitsHeight)
            {
                columnWidth = Math.min(availableWidth, board.controlsHeight() > 0 ? Math.max(boardWidth, BoardLayoutTier.MIN_CONTROL_ROW_WIDTH) : boardWidth);
                if (boardWidth < columnWidth) // the control row above the board keeps its width while the board narrows
                    boardMaxWidth = boardWidth;
            }
            else if (boardWidth < availableWidth) // only the board narrows: the bars and the control row keep the full width
                boardMaxWidth = boardWidth;
        }
        column.width = Math.max(0, Math.floor(columnWidth));
        board.setBoardMaxWidth(boardMaxWidth);

        var requestsWidth:Float = Math.min(columnWidth - 2 * REQUESTS_INSET, REQUESTS_MAX_WIDTH);
        requests.width = requestsWidth;
        requests.left = (columnWidth - requestsWidth) / 2;
        onFitted();
    }
}
