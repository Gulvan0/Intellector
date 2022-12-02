package net.shared.board;

enum InternalMaterializedPly 
{
    NormalMove(from:HexCoords, to:HexCoords, movingPiece:PieceType);
    NormalCapture(from:HexCoords, to:HexCoords, capturingPiece:PieceType, capturedPiece:PieceType);
    ChameleonCapture(from:HexCoords, to:HexCoords, capturingPiece:PieceType, capturedPiece:PieceType);
    Promotion(from:HexCoords, to:HexCoords, promotedTo:PieceType);
    PromotionWithCapture(from:HexCoords, to:HexCoords, capturedPiece:PieceType, promotedTo:PieceType);
    Castling(from:HexCoords, to:HexCoords);
}

abstract MaterializedPly(InternalMaterializedPly) from InternalMaterializedPly to InternalMaterializedPly
{
    public static function construct(pieces:PieceArrangement, from:HexCoords, to:HexCoords, morphInto:Null<PieceType>):MaterializedPly 
    {
        if (!pieces.empty(to))
            if (pieces.colorAt(from) == pieces.colorAt(to))
                return Castling(from, to);
            else if (morphInto == null)
                return NormalCapture(from, to, pieces.typeAt(from), pieces.typeAt(to));
            else if (pieces.typeAt(from) == Progressor)
                return PromotionWithCapture(from, to, pieces.typeAt(to), morphInto);
            else
                return ChameleonCapture(from, to, pieces.typeAt(from), pieces.typeAt(from));
        else if (morphInto != null)
            return Promotion(from, to, morphInto);
        else
            return NormalMove(from, to, pieces.typeAt(from));
    }

    public function isMating():Bool
    {
        switch this 
        {
            case NormalCapture(_, _, _, capturedPiece), ChameleonCapture(_, _, _, capturedPiece), PromotionWithCapture(_, _, capturedPiece, _):
                return capturedPiece == Intellector;
            default:
                return false;
        }
    }

    public function isBreakthrough(pieces:PieceArrangement, turnColor:PieceColor):Bool
    {
        switch this 
        {
            case NormalMove(from, to, movingPiece):
                return movingPiece == Intellector && to.isFinal(turnColor);
            case Castling(from, to):
                if (pieces.typeAt(from) == Intellector)
                    return to.isFinal(turnColor);
                else
                    return from.isFinal(turnColor);
            default:
                return false;
        }
    }

    public function isProgressive():Bool
    {
        switch this 
        {
            case NormalMove(_, _, movingPiece):
                return movingPiece == Progressor;
            case NormalCapture(_, _, _, _), ChameleonCapture(_, _, _, _), Promotion(_, _, _), PromotionWithCapture(_, _, _, _):
                return true;
            case Castling(_, _):
                return false;
        }
    }

    public function toRaw():RawPly
    {
        switch this 
        {
            case NormalMove(from, to, _), NormalCapture(from, to, _, _), Castling(from, to):
                return RawPly.construct(from, to);
            case ChameleonCapture(from, to, _, morphInto), Promotion(from, to, morphInto), PromotionWithCapture(from, to, _, morphInto):
                return RawPly.construct(from, to, morphInto);
        }
    }

    public function toString():String
    {
        return Std.string(this);
    }
}