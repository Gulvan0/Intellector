package client.datatypes.variations;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;

/** A position being edited, starting from `original`. Every edit replaces `position` with a new one **/
class PositionDraft
{
    public final original:Position;
    public var position(default, null):Position;

    public function new(original:Position)
    {
        this.original = original;
        this.position = original.copy();
    }

    public function movePiece(from:HexCoords, to:HexCoords):Void
    {
        if (from.equals(to))
            return;

        var edited:Position = position.copy();
        edited.set(to, edited.get(from));
        edited.set(from, Empty);
        position = edited;
    }

    public function placePiece(hex:HexCoords, piece:PieceData):Void
    {
        var edited:Position = position.copy();
        edited.set(hex, Occupied(piece));
        position = edited;
    }

    public function clearHex(hex:HexCoords):Void
    {
        var edited:Position = position.copy();
        edited.set(hex, Empty);
        position = edited;
    }

    public function setTurnColor(color:PieceColor):Void
    {
        position = position.copy(color);
    }

    /** Removes every piece; the side to move stays **/
    public function clear():Void
    {
        position = Position.empty().copy(position.turnColor);
    }

    /** Back to `original`, side to move included **/
    public function reset():Void
    {
        position = original.copy();
    }

    public function setStarting():Void
    {
        position = Position.defaultStarting();
    }

    public function setPosition(newPosition:Position):Void
    {
        position = newPosition.copy();
    }

    public function isChanged():Bool
    {
        return position.turnColor != original.turnColor || position.getHash() != original.getHash();
    }

    public function isClear():Bool
    {
        return position.countPieces() == 0;
    }

    public function isStarting():Bool
    {
        return position.isDefaultStarting();
    }

    /** Whether analysis may start from it: one Intellector a side, neither on its last rank **/
    public function isValid():Bool
    {
        return position.isValidStarting();
    }
}
