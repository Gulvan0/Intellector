package gameboard.states;

import struct.Hex;
import struct.IntPoint;

private enum Transition
{
    ToNeutral;
    ToDragging(dragStartLocation:IntPoint);
}

class SelectedState extends BasePlayableState
{
    public var selectedDepartureLocation:IntPoint;

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
            case ToDragging(dragStartLocation):
                boardInstance.state = new DraggingState(dragStartLocation);
        }
    }

    public function exitToNeutral()
    {
        exit(ToNeutral);
    }

    public function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        var pressedDestinationHex:Null<Hex> = location == null? null : boardInstance.shownSituation.get(location);
        var selectedDepartureHex:Hex = boardInstance.shownSituation.get(selectedDepartureLocation);

        if (pressedDestinationHex == null)
            exit(ToNeutral);
        else if (boardInstance.behavior.movePossible(selectedDepartureLocation, location))
        {
            exit(ToNeutral);
            askMoveDetails(selectedDepartureLocation, location, shiftPressed, ctrlPressed);
        }
        else if (pressedDestinationHex.color == selectedDepartureHex.color)
            exit(ToDragging(location));
        else
            exit(ToNeutral);
    }

    public function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.behavior.movePossible(selectedDepartureLocation, location);
    }

    public function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new(selectedDepartureLocation:IntPoint)
    {
        this.selectedDepartureLocation = selectedDepartureLocation;
    }
}