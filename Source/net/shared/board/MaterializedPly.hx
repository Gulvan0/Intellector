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
                return ChameleonCapture(from, to, pieces.typeAt(from), pieces.typeAt(to));
        else if (morphInto != null)
            return Promotion(from, to, morphInto);
        else
            return NormalMove(from, to, pieces.typeAt(from));
    }

    public function underlying():InternalMaterializedPly
    {
        return this;
    }

    public function equals(other:MaterializedPly):Bool
    {
        return switch [this, other]
        {
            case [NormalMove(from, to, movingPiece), NormalMove(from2, to2, movingPiece2)]: 
                from.equals(from2) && to.equals(to2) && movingPiece == movingPiece2;
            case [NormalCapture(from, to, capturingPiece, capturedPiece), NormalCapture(from2, to2, capturingPiece2, capturedPiece2)]:
                from.equals(from2) && to.equals(to2) && capturingPiece == capturingPiece2 && capturedPiece == capturedPiece2;
            case [ChameleonCapture(from, to, capturingPiece, capturedPiece), ChameleonCapture(from2, to2, capturingPiece2, capturedPiece2)]:
                from.equals(from2) && to.equals(to2) && capturingPiece == capturingPiece2 && capturedPiece == capturedPiece2;
            case [Promotion(from, to, promotedTo), Promotion(from2, to2, promotedTo2)]:
                from.equals(from2) && to.equals(to2) && promotedTo == promotedTo2;
            case [PromotionWithCapture(from, to, capturedPiece, promotedTo), PromotionWithCapture(from2, to2, capturedPiece2, promotedTo2)]:
                from.equals(from2) && to.equals(to2) && promotedTo == promotedTo2 && capturedPiece == capturedPiece2;
            case [Castling(from, to), Castling(from2, to2)]:
                from.equals(from2) && to.equals(to2) || from.equals(to2) && to.equals(from2);
            default:
                false;
        }
    }

    public function affectedCoords():Array<HexCoords>
    {
        switch this 
        {
            case NormalMove(from, to, _), NormalCapture(from, to, _, _), ChameleonCapture(from, to, _, _), Promotion(from, to, _), PromotionWithCapture(from, to, _, _), Castling(from, to):
                return [from, to];
        }
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