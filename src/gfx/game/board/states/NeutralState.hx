package gfx.game.board.states;

import gfx.utils.Colors;
import haxe.ui.geom.Point;
import net.shared.board.Hex;
import gfx.game.events.GameboardEvent;
import haxe.ui.events.MouseEvent;
import net.shared.board.HexCoords;

using Lambda;

class NeutralState implements IState 
{
    private var boardInstance:GameBoard;
    public var cursorLocation(default, null):Null<HexCoords>;

    public function onEntered() 
    {
        if (isHoverNeeded(cursorLocation))
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
        boardInstance.eventHandler(LMBPressed(location));
        boardInstance.removeAllArrows(Colors.arrow);

        if (location == null)
            return;

        switch boardInstance.mode 
        {
            case PlySelection(getAllowedDestinations):
                var allowedDestinations:Array<HexCoords> = getAllowedDestinations(location);
                if (!allowedDestinations.empty())
                {
                    boardInstance.showHexLayer(location, SelectedForMove);

                    for (markerLocation in allowedDestinations)
                        boardInstance.addMarker(markerLocation);

                    var dragStartScreenCoords:Point = new Point(originalEvent.screenX, originalEvent.screenY);
                    var isDestinationAllowed = dest -> allowedDestinations.exists(x -> x.equals(dest));
                    boardInstance.state = new DraggingState(boardInstance, cursorLocation, location, dragStartScreenCoords, isDestinationAllowed);
                }
            case HexSelection(isSelectable):
                if (isSelectable(location))
                    boardInstance.eventHandler(HexSelected(location));
            case FreeMove(canBeMoved):
                if (canBeMoved(location))
                {
                    boardInstance.showHexLayer(location, SelectedForMove);

                    var dragStartScreenCoords:Point = new Point(originalEvent.screenX, originalEvent.screenY);
                    var isDestinationAllowed = dest -> !location.equals(dest);
                    boardInstance.state = new DraggingState(boardInstance, cursorLocation, location, dragStartScreenCoords, isDestinationAllowed);
                }
            case NotInteractive:
                //* Do nothing
        }
    }

    public function onMouseMoved(newCursorLocation:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        if (equal(cursorLocation, newCursorLocation))
            return;

        if (isHoverNeeded(newCursorLocation))
            boardInstance.showHexLayer(newCursorLocation, Hover);
        else
            boardInstance.hideLayerForEveryHex(Hover);

        cursorLocation = newCursorLocation;
    }

    public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent) 
    {
        //* Do nothing
    }

    private function isHoverNeeded(hoverLocation:Null<HexCoords>)
    {
        return hoverLocation != null && switch boardInstance.mode 
        {
            case PlySelection(getAllowedDestinations):
                !getAllowedDestinations(cursorLocation).empty();
            case HexSelection(isSelectable):
                isSelectable(cursorLocation);
            case FreeMove(canBeMoved):
                canBeMoved(cursorLocation);
            case NotInteractive: 
                false;
        }
    }

    public function new(boardInstance:GameBoard, cursorLocation:Null<HexCoords>) 
    {
        this.boardInstance = boardInstance;
        this.cursorLocation = cursorLocation;
    }    
}