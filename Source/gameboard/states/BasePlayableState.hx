package gameboard.states;

import struct.Hex;
import struct.IntPoint;
import net.ServerEvent;

class BasePlayableState extends BaseState
{
    private function askMoveDetails(from:IntPoint, to:IntPoint) 
    {
        var departureHex:Hex = boardInstance.shownSituation.get(from);
        var destinationHex:Hex = boardInstance.shownSituation.get(to);
        var nearIntellector:Bool = Rules.areNeighbours(from, boardInstance.shownSituation.intellectorPos[departureHex.color]);
        
        var promotionPossible:Bool = to.isFinalForColor(departureHex.color) && departureHex.type == Progressor && destinationHex.color != departureHex.color && destinationHex.type != Intellector;
        var chameleonPossible:Bool = nearIntellector && !destinationHex.isEmpty() && departureHex.color != destinationHex.color && departureHex.type != destinationHex.type && departureHex.type != Progressor && destinationHex.type != Intellector;
        
        var simplePly:Ply = Ply.construct(from, to);
        var chameleonPly:Ply = Ply.construct(from, to, destinationHex.type);

        var onChameleonDecisionMade = (morph:Bool) -> {boardInstance.behavior.onMoveChosen(morph? chameleonPly : simplePly);};
        var onPromotionSelected = (piece:PieceType) -> {boardInstance.behavior.onMoveChosen(Ply.construct(from, to, piece));};

        if (promotionPossible)
            Dialogs.promotionSelect(departureHex.color, onPromotionSelected, abortMove);
        else if (chameleonPossible)
            Dialogs.chameleonConfirm(onChameleonDecisionMade, abortMove);
        else
            boardInstance.behavior.onMoveChosen(simplePly);
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}