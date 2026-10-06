package client.ui.common.board.tools;

import client.ui.common.board.MoveRules;
import client.ui.common.board.Premoves;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;

/**
    The user's own pieces in a live game: legal moves on their turn, premoves (if `premoves` is given
    and enabled) on the opponent's. The turn is the real position's, not the premove-advanced one.
**/
class LiveGameMovePolicy implements PieceMovePolicy
{
    private final rules:MoveRules;
    private final userColor:PieceColor;
    private final premoves:Null<Premoves>;

    public function new(rules:MoveRules, userColor:PieceColor, premoves:Null<Premoves>)
    {
        this.rules = rules;
        this.userColor = userColor;
        this.premoves = premoves;
    }

    public function pickMode(position:Position):Null<PieceMoveMode>
    {
        var realTurn:PieceColor = premoves != null ? premoves.realTurn() : position.turnColor;

        if (realTurn == userColor)
            return Move;
        if (premoves != null && premoves.isEnabled())
            return Premove;
        return null;
    }

    public function canPickUp(position:Position, mode:PieceMoveMode, hex:HexCoords):Bool
    {
        var piece:Null<PieceData> = position.getPiece(hex);
        return piece != null && piece.color == userColor;
    }

    public function destinations(position:Position, mode:PieceMoveMode, from:HexCoords):Null<Array<HexCoords>>
    {
        return mode == Premove ? rules.getPremoveDestinations(from, position.pieces) : rules.getLegalDestinations(from, position.pieces);
    }

    public function completion(position:Position, mode:PieceMoveMode, from:HexCoords, to:HexCoords):CompletionKind
    {
        if (mode != Premove)
            return MoveCompletion.ofMove(rules, position, from, to);

        var movingPiece:PieceData = position.getPiece(from);
        if (rules.isPromotionPossible(movingPiece, to))
            return Promotion;
        if (isPremoveChameleonEligible(position, movingPiece, from, to))
            return PremoveChameleon;
        return None;
    }

    public function showsMarkers(mode:PieceMoveMode):Bool
    {
        return mode != Premove;
    }

    /** While premoves are queued, the position the choice was made for is still coming **/
    public function keepsChoiceAcrossMove(position:Position):Bool
    {
        return premoves != null && premoves.hasQueued();
    }

    // not a Progressor or Intellector move, not the Intellector-Defensor swap, and the aura active
    private function isPremoveChameleonEligible(position:Position, movingPiece:PieceData, from:HexCoords, to:HexCoords):Bool
    {
        if (movingPiece.type == Progressor || movingPiece.type == Intellector)
            return false;

        var target:Null<PieceData> = position.getPiece(to);
        if (movingPiece.type == Defensor && target != null && target.color == movingPiece.color && target.type == Intellector)
            return false;

        return rules.isAuraActive(from, position.pieces);
    }
}
