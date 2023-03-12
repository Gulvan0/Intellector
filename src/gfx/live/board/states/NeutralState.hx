package gfx.live.board.states;

import haxe.ui.geom.Point;
import net.shared.board.Hex;
import gfx.live.events.GameboardEvent;
import haxe.ui.events.MouseEvent;
import net.shared.board.HexCoords;

class NeutralState implements IState 
{
	private var boardInstance:GameBoard;
	public var cursorLocation(default, null):Null<HexCoords>;

    public function onEntered() 
    {
        var hexRetriever:HexCoords->Hex = boardInstance.globalStateRef.getShownSituation().get;

        var hoverNeeded:Bool = switch boardInstance.mode 
        {
            case MoveSelection(controllablePieces, _):
                cursorLocation != null && controllablePieces.contains(hexRetriever(cursorLocation).color());
            case HexSelection(selectabilityChecker):
                cursorLocation != null && selectabilityChecker(cursorLocation, hexRetriever);
            case NotInteractive: 
                false;
        }

        if (hoverNeeded)
            boardInstance.showHexLayer(cursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);
    }

	public function exit() 
    {
        //* Do nothing
    }

	public function onLMBPressed(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        var hexRetriever:HexCoords->Hex = boardInstance.globalStateRef.getShownSituation().get;

        var hexUnderCursor:Hex = Empty;
        if (location != null)
            hexUnderCursor = hexRetriever(location);

        boardInstance.eventHandler(LMBPressed(hexUnderCursor));

        if (location == null)
            return;

        switch boardInstance.mode 
        {
            case MoveSelection(controllablePieces, allowedDestinations):
                var isControllable:Bool = controllablePieces.contains(hexUnderCursor.color());
                if (isControllable)
                {
                    boardInstance.showHexLayer(location, SelectedForMove);

                    if (allowedDestinations != null)
                        for (markerLocation in allowedDestinations(location, hexRetriever))
                            boardInstance.addMarker(markerLocation);

                    var dragStartScreenCoords:Point = new Point(originalEvent.screenX, originalEvent.screenY);
                    var isDestinationAllowed = dest -> allowedDestinations(location, hexRetriever).contains(dest);
                    boardInstance.state = new DraggingState(boardInstance, cursorLocation, location, dragStartScreenCoords, isDestinationAllowed);
                }
            case HexSelection(selectabilityChecker):
                var isSelectable:Bool = selectabilityChecker(location, hexRetriever);
                if (isSelectable)
                    boardInstance.eventHandler(HexSelected(location));
            case NotInteractive:
                //* Do nothing
        }
    }

	public function onMouseMoved(newCursorLocation:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        if (equal(cursorLocation, newCursorLocation))
            return;

        var hexRetriever:HexCoords->Hex = boardInstance.globalStateRef.getShownSituation().get;

        var hoverNeeded:Bool = switch boardInstance.mode 
        {
            case MoveSelection(controllablePieces, _):
                newCursorLocation != null && controllablePieces.contains(hexRetriever(newCursorLocation).color());
            case HexSelection(selectabilityChecker):
                newCursorLocation != null && selectabilityChecker(newCursorLocation, hexRetriever);
            case NotInteractive: 
                false;
        }

        if (hoverNeeded)
            boardInstance.showHexLayer(newCursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);

        cursorLocation = newCursorLocation;
    }

	public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        //* Do nothing
    }

    public function new(boardInstance:GameBoard, cursorLocation:Null<HexCoords>) 
    {
        this.boardInstance = boardInstance;
        this.cursorLocation = cursorLocation;
    }    
}