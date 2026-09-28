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

    `isPromotionPossible`/`isChameleonPossible` are thin wrappers around
    `CoreRules.isPromotionEligible`/`isChameleonEligible` - the same predicates
    `PlyRules.possiblePlys` itself uses to decide when a generated ply needs a `morphInto`, so
    there's one definition of "is this a promotion/chameleon" rather than a second one re-derived
    here.
**/
class MoveRulesAdapter
{
    public static final DEFAULT:MoveRules = {
        getLegalDestinations: (from, position) -> MoveDestinations.getPossibleDestinations(from, position.pieces),
        isPromotionPossible: isPromotionPossible,
        isChameleonPossible: isChameleonPossible
    };

    private static function isPromotionPossible(from:HexCoords, to:HexCoords, position:Position):Bool
    {
        var movingPiece:Null<PieceData> = position.getPiece(from);
        return movingPiece != null && CoreRules.isPromotionEligible(movingPiece, to);
    }

    private static function isChameleonPossible(from:HexCoords, to:HexCoords, position:Position):Bool
    {
        var movingPiece:Null<PieceData> = position.getPiece(from);
        if (movingPiece == null)
            return false;

        return CoreRules.isChameleonEligible(position.pieces, from, movingPiece, position.getPiece(to));
    }
}
