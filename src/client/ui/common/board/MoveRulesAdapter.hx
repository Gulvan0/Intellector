package client.ui.common.board;

import intellectorboard.movement.rules.MoveDestinations;
import intellectorboard.movement.rules.CoreRules;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;

/**
    The real `MoveRules`, delegating to `intellectorboard`. Lives in the same package as
    `BoardSurface` (which already depends on `intellectorboard` for its own rendering), so
    `MoveInteractionController` itself stays free of that dependency - see `MoveRules`.
**/
class MoveRulesAdapter
{
    public static final DEFAULT:MoveRules = {
        getLegalDestinations: (from, position) -> MoveDestinations.getPossibleDestinations(from, position.pieces),
        isPromotionPossible: isPromotionPossible,
        isChameleonPossible: isChameleonPossible
    };

    /*
        Ported from the old BasePlayableState.askMoveDetails: a Progressor reaching the final rank
        promotes, unless the destination holds the enemy Intellector - capturing that is Fatum
        (an immediate win), not a promotion choice.
    */
    private static function isPromotionPossible(from:HexCoords, to:HexCoords, position:Position):Bool
    {
        var departure:Null<PieceData> = position.getPiece(from);
        if (departure == null || departure.type != Progressor || !to.isFinal(departure.color))
            return false;

        var destination:Null<PieceData> = position.getPiece(to);
        return destination == null || destination.type != Intellector;
    }

    /*
        Ported from the old BasePlayableState.askMoveDetails: capturing an enemy piece of a
        different kind, while affected by a friendly Intellector's aura, may "chameleon" into the
        captured piece's kind - except a Progressor (which promotes instead) or the enemy
        Intellector itself (which is Fatum, not a chameleon capture).
    */
    private static function isChameleonPossible(from:HexCoords, to:HexCoords, position:Position):Bool
    {
        var departure:Null<PieceData> = position.getPiece(from);
        var destination:Null<PieceData> = position.getPiece(to);

        if (departure == null || destination == null)
            return false;
        if (departure.type == Progressor || destination.type == Intellector)
            return false;
        if (destination.color == departure.color || destination.type == departure.type)
            return false;

        return CoreRules.isHexAffectedByAura(position.pieces, from);
    }
}
