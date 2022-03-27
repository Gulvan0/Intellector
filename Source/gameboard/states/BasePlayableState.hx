package gameboard.states;

import struct.PieceType;
import gfx.components.Dialogs;
import struct.Hex;
import struct.Ply;
import struct.IntPoint;
import net.ServerEvent;

class BasePlayableState extends BaseState
{
    private function askMoveDetails(from:IntPoint, to:IntPoint, shiftPressed:Bool, ctrlPressed:Bool) 
    {
        var departureHex:Hex = boardInstance.shownSituation.get(from);
        var destinationHex:Hex = boardInstance.shownSituation.get(to);
        var nearIntellector:Bool = Rules.areNeighbours(from, boardInstance.shownSituation.intellectorPos[departureHex.color]);
        
        var promotionPossible:Bool = to.isFinalForColor(departureHex.color) && departureHex.type == Progressor && destinationHex.color != departureHex.color && destinationHex.type != Intellector;
        var chameleonPossible:Bool = nearIntellector && !destinationHex.isEmpty() && departureHex.color != destinationHex.color && departureHex.type != destinationHex.type && departureHex.type != Progressor && destinationHex.type != Intellector;
        
        var simplePly:Ply = Ply.construct(from, to);
        var chameleonPly:Ply = Ply.construct(from, to, destinationHex.type);
        var dominatorPromotionPly:Ply = Ply.construct(from, to, Dominator);

        var onChameleonDecisionMade = (morph:Bool) -> {boardInstance.behavior.onMoveChosen(morph? chameleonPly : simplePly);};
        var onPromotionSelected = (piece:PieceType) -> {boardInstance.behavior.onMoveChosen(Ply.construct(from, to, piece));};

        if (promotionPossible)
            if (shiftPressed)
                boardInstance.behavior.onMoveChosen(dominatorPromotionPly);
            else
                Dialogs.promotionSelect(departureHex.color, onPromotionSelected, abortMove);
        else if (chameleonPossible)
            if (ctrlPressed)
                boardInstance.behavior.onMoveChosen(simplePly);
            else if (shiftPressed)
                boardInstance.behavior.onMoveChosen(chameleonPly);
            else
                Dialogs.chameleonConfirm(onChameleonDecisionMade, abortMove);
        else
            boardInstance.behavior.onMoveChosen(simplePly);
    }

    public function new(board:GameBoard, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
    }
}