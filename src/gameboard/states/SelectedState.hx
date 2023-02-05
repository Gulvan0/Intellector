package gameboard.states;

import haxe.ui.geom.Point;
import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import net.shared.board.Hex;

private enum Transition
{
    ToNeutral;
    ToDragging(dragStartLocation:HexCoords, screenCoords:Point);
}

class SelectedState extends BasePlayableState
{
    public var selectedDepartureLocation:HexCoords;

    public function onEntered()
    {
        boardInstance.getHex(selectedDepartureLocation).showLayer(LMB);

        if (!boardInstance.behavior.markersDisabled())
            boardInstance.addMarkers(selectedDepartureLocation);
    }

    private function exit(transition:Transition)
    {
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);

        if (!boardInstance.behavior.markersDisabled())
            boardInstance.removeMarkers(selectedDepartureLocation);

        switch transition 
        {
            case ToNeutral:
                boardInstance.state = new NeutralState();
            case ToDragging(dragStartLocation, screenCoords):
                boardInstance.state = new DraggingState(dragStartLocation, screenCoords);
        }
    }

    public function exitToNeutral()
    {
        exit(ToNeutral);
    }

    public function onLMBPressed(location:Null<HexCoords>, screenCoords:Point, shiftPressed:Bool, ctrlPressed:Bool)
    {
        var pressedDestinationHex:Null<Hex> = location == null? null : boardInstance.shownSituation.get(location);
        var selectedDepartureHex:Hex = boardInstance.shownSituation.get(selectedDepartureLocation);

        if (pressedDestinationHex == null || location.equals(selectedDepartureLocation))
            exit(ToNeutral);
        else if (boardInstance.behavior.movePossible(selectedDepartureLocation, location))
        {
            exit(ToNeutral);
            askMoveDetails(selectedDepartureLocation, location, shiftPressed, ctrlPressed);
        }
        else if (pressedDestinationHex.color() == selectedDepartureHex.color())
            exit(ToDragging(location, screenCoords));
        else
            exit(ToNeutral);
    }

    public function reactsToHover(location:HexCoords):Bool
    {
        return boardInstance.behavior.movePossible(selectedDepartureLocation, location);
    }
    
    private function isHoverStrong():Bool
    {
        return false;
    }

    public function onLMBReleased(location:Null<HexCoords>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new(selectedDepartureLocation:HexCoords)
    {
        this.selectedDepartureLocation = selectedDepartureLocation;
    }
}