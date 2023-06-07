package gfx.game.board.states;

import gfx.game.events.util.MoveIntentOptions;
import gfx.game.events.util.FastChameleonOption;
import gfx.game.events.util.FastPromotionOption;
import gfx.utils.SpecialControlSettings;
import gfx.game.events.GameboardEvent;
import haxe.ui.geom.Point;
import net.shared.board.HexCoords;
import haxe.ui.events.MouseEvent;
import net.shared.board.Hex;

using Lambda;

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

    public function onLMBPressed(location:Null<HexCoords>, originalEvent:MouseEvent, specialControlSettings:SpecialControlSettings) 
    {
        exit();

        if (location == null || location.equals(selectedLocation))                                          //Out of board or same => deselect
            boardInstance.state = new NeutralState(boardInstance, cursorLocation);
        else if (isDestinationAllowed(location))                                                            //Allowed => perform move
        {
            boardInstance.state = new NeutralState(boardInstance, cursorLocation);
            if (boardInstance.mode.match(PlySelection(_)))
            {
                var fastPromotion:FastPromotionOption = specialControlSettings.fastPromotion || originalEvent.shiftKey? AutoPromoteToDominator : Ask;
                var fastChameleon:FastChameleonOption = originalEvent.shiftKey? AutoAccept : originalEvent.ctrlKey? AutoDecline : Ask;
                var moveIntentOptions:MoveIntentOptions = new MoveIntentOptions(fastPromotion, fastChameleon);
                boardInstance.getBehaviour().handleGameboardEvent(MoveAttempted(selectedLocation, location, moveIntentOptions));
            }
            else
                boardInstance.getBehaviour().handleGameboardEvent(FreeMovePerformed(selectedLocation, location));
        }
        else                                                                                                //Not allowed, but on board => if draggable, start dragging, otherwise deselect
        {
            switch boardInstance.mode 
            {
                case PlySelection(getAllowedDestinations):
                    var allowedDestinations:Array<HexCoords> = getAllowedDestinations(location);
                    if (!allowedDestinations.empty())
                    {
                        var newDragStartScreenCoords:Point = new Point(originalEvent.screenX, originalEvent.screenY);
                        var newIsDestinationAllowed = dest -> allowedDestinations.exists(x -> x.equals(dest));
                        boardInstance.state = new DraggingState(boardInstance, cursorLocation, location, newDragStartScreenCoords, newIsDestinationAllowed);
                    }
                    else
                        boardInstance.state = new NeutralState(boardInstance, cursorLocation);
                default:
                    return; //No FreeMove case because any destination is allowed in that mode
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

    public function onLMBReleased(location:Null<HexCoords>, originalEvent:MouseEvent, specialControlSettings:SpecialControlSettings) 
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