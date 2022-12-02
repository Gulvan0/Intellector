package gameboard.states;

import net.shared.PieceType;
import gfx.Dialogs;
import net.shared.ServerEvent;

abstract class BasePlayableState extends BaseState
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

        var onChameleonDecisionMade = (morph:Bool) -> {onMoveChosen(morph? chameleonPly : simplePly);};
        var onPromotionSelected = (piece:PieceType) -> {onMoveChosen(Ply.construct(from, to, piece));};

        if (promotionPossible)
            if (shiftPressed)
                onMoveChosen(dominatorPromotionPly);
            else
                Dialogs.promotionSelect(departureHex.color, onPromotionSelected);
        else if (chameleonPossible)
            if (ctrlPressed)
                onMoveChosen(simplePly);
            else if (shiftPressed)
                onMoveChosen(chameleonPly);
            else
                Dialogs.chameleonConfirm(onChameleonDecisionMade);
        else
            onMoveChosen(simplePly);
    }

    private function onMoveChosen(ply:Ply)
    {
        boardInstance.behavior.onMoveChosen(ply);
        boardInstance.state.updateHoverEffects(); //We need to use boardInstance as the state may be different afterwards
    }
}