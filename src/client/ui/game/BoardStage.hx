package client.ui.game;

import client.datatypes.game.GameParticipant;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.InteractiveBoard;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import morestd.Detachable;

/**
    The board between its two player bars, as wide as the area allows - and, while it fits the
    height too, no taller than it. Requests (offers, confirmations) sit over the board's top edge.
**/
class BoardStage extends Box
{
    private static inline final BAR_HEIGHT:Float = 48;
    private static inline final BAR_GAP:Float = 12;
    private static inline final REQUESTS_MAX_WIDTH:Float = 440;
    private static inline final REQUESTS_INSET:Float = 10;
    // until the first fit: the board is as wide as the column, so the column can't size to its content
    private static inline final PROVISIONAL_WIDTH:Float = 400;

    public final topBar:PlayerBar;
    public final bottomBar:PlayerBar;
    public final requests:VBox;

    private final column:VBox;
    private final observer:Dynamic;
    private final coordinatesHandle:Detachable;
    private var fitsHeight:Bool = true;

    public function new(board:InteractiveBoard, onNicknameClicked:GameParticipant->Void)
    {
        super();
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.GAME_STAGE);

        column = new VBox();
        column.addClass(StyleClass.GAME_STAGE_COLUMN);
        column.horizontalAlign = "center";
        column.verticalAlign = "center";
        column.width = PROVISIONAL_WIDTH;
        addComponent(column);

        topBar = new PlayerBar(onNicknameClicked);
        topBar.addClass(StyleClass.GAME_PLAYER_BAR_TOP);
        column.addComponent(topBar);

        board.percentWidth = 100;
        column.addComponent(board);

        bottomBar = new PlayerBar(onNicknameClicked);
        bottomBar.addClass(StyleClass.GAME_PLAYER_BAR_BOTTOM);
        column.addComponent(bottomBar);

        requests = new VBox();
        requests.addClass(StyleClass.GAME_REQUESTS);
        requests.includeInLayout = false;
        column.addComponent(requests);

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
        if (fitsHeight)
        {
            var aspectRatio:Float = BoardSurface.aspectRatioOf(Preferences.boardCoordinates.get());
            columnWidth = Math.min(availableWidth, (this.element.clientHeight - 2 * (BAR_HEIGHT + BAR_GAP)) * aspectRatio);
        }
        column.width = Math.max(0, Math.floor(columnWidth));

        var requestsWidth:Float = Math.min(columnWidth - 2 * REQUESTS_INSET, REQUESTS_MAX_WIDTH);
        requests.width = requestsWidth;
        requests.left = (columnWidth - requestsWidth) / 2;
        requests.top = BAR_HEIGHT + BAR_GAP + REQUESTS_INSET;
    }
}
