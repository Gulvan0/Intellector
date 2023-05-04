package gfx.game.board.states;

import gfx.game.events.GameboardEvent;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import haxe.ui.events.MouseEvent;
import net.shared.board.Hex;

class SelectedState implements IState
{
    private var boardInstance:GameBoard;
	public var cursorLocation(default, null):Null<HexCoords>;

    private var selectedLocation:HexCoords;
    private var isDestinationAllowed:HexCoords->Bool;

    public function onEntered() 
    {
        if (cursorLocation != null && isDestinationAllowed(cursorLocation))
            boardInstance.showHexLayer(cursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);
    }

	public function exit() 
    {
        boardInstance.getHex(selectedLocation).hideLayer(SelectedForMove);
        boardInstance.hideLayerForEveryHex(Hover);
        boardInstance.removeAllMarkers();
    }

	public function onLMBPressed(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        var hexRetriever:HexCoords->Hex = boardInstance.globalStateRef.getShownSituation().get;

        var pressedDestinationHex:Null<Hex> = location == null? null : hexRetriever(location);
        var selectedDepartureHex:Hex = hexRetriever(selectedLocation);

        exit();

        if (pressedDestinationHex == null || location.equals(selectedLocation))
            boardInstance.state = new NeutralState(boardInstance, cursorLocation);
        else if (location != null && isDestinationAllowed(location))
        {
            boardInstance.state = new NeutralState(boardInstance, cursorLocation);
            boardInstance.eventHandler(MoveAttempted(selectedLocation, location, {
                fastPromotion: originalEvent.shiftKey? AutoPromoteToDominator : Ask,
                fastChameleon: originalEvent.shiftKey? AutoAccept : originalEvent.ctrlKey? AutoDecline : Ask
            }));
        }
        else
        {
            switch boardInstance.mode 
            {
                case MoveSelection(controllablePieces, allowedDestinations):
                    if (controllablePieces.contains(pressedDestinationHex.color()))
                    {
                        var newDragStartScreenCoords:Point = new Point(originalEvent.screenX, originalEvent.screenY);
                        var newIsDestinationAllowed = dest -> allowedDestinations(location, hexRetriever).contains(dest);
                        boardInstance.state = new DraggingState(boardInstance, cursorLocation, location, newDragStartScreenCoords, newIsDestinationAllowed);
                    }
                    else
                        boardInstance.state = new NeutralState(boardInstance, cursorLocation);
                default:
                    return;
            }
        }
    }

	public function onMouseMoved(newCursorLocation:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        if (equal(cursorLocation, newCursorLocation))
            return;

        if (newCursorLocation != null && isDestinationAllowed(newCursorLocation))
            boardInstance.showHexLayer(newCursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);

        cursorLocation = newCursorLocation;
    }

	public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        //* Do nothing
    }

    public function new(boardInstance:GameBoard, cursorLocation:Null<HexCoords>, selectedLocation:HexCoords, isDestinationAllowed:HexCoords->Bool) 
    {
        this.boardInstance = boardInstance;
        this.cursorLocation = cursorLocation;

        this.selectedLocation = selectedLocation;
        this.isDestinationAllowed = isDestinationAllowed;
    }
}