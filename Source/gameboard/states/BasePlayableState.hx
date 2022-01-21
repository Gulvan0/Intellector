package gameboard.states;

import struct.Hex;
import struct.IntPoint;
import net.ServerEvent;

class BasePlayableState extends BaseState
{
    private function onMoveCanceled(departureCoords:IntPoint) 
    {
        throw "Should be overriden";
    }

    private function onMoveChosen(ply:Ply)
    {
        throw "Should be overriden";
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return movePossible(selectedDepartureLocation, location);
    }

    private function askMoveDetails(from:IntPoint, to:IntPoint) 
    {
        var departureHex:Hex = boardInstance.shownSituation.get(from);
        var destinationHex:Hex = boardInstance.shownSituation.get(to);
        var nearIntellector:Bool = Rules.areNeighbours(from, boardInstance.shownSituation.intellectorPos[departureHex.color]);
        
        var promotionPossible:Bool = to.isFinalForColor(departureHex.color) && departureHex.type == Progressor && destinationHex.color != departureHex.color && destinationHex.type != Intellector;
        var chameleonPossible:Bool = nearIntellector && !destinationHex.isEmpty() && departureHex.color != destinationHex.color && departureHex.type != destinationHex.type && departureHex.type != Progressor && destinationHex.type != Intellector;
        
        var simplePly:Ply = Ply.construct(from, to);
        var chameleonPly:Ply = Ply.construct(from, to, destinationHex.type);

        var onCanceled:Void->Void = onMoveCanceled.bind(from);
        var onChameleonDecisionMade = (morph:Bool) -> {onMoveChosen(morph? chameleonPly : simplePly);};
        var onPromotionSelected = (piece:PieceType) -> {onMoveChosen(Ply.construct(from, to, piece));};

        if (promotionPossible)
            Dialogs.promotionSelect(departureHex.color, onPromotionSelected, onCanceled);
        else if (chameleonPossible)
            Dialogs.chameleonConfirm(onChameleonDecisionMade, onCanceled);
        else
            onMoveChosen(simplePly);
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}