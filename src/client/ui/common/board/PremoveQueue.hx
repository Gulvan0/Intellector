package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.ply.RawPly;

using Lambda;

/**
    The premoves a user has planned, in the order they'll be played. Pure data and rules - no
    board, no events - so `MoveInteractionController` can drive it and a test can too.

    Nothing is checked when a premove is `add`ed: it's only a plan. `applyTo` shows what the board
    would look like if all of them had been played (a bare transposition of pieces, so the same
    piece can be premoved again from its destination), and `takeNext` is where a premove is finally
    validated - only the first one, against the position it would really be played in; if it
    fails, the whole queue goes with it.
**/
class PremoveQueue
{
    private var plies:Array<RawPly> = [];

    public function new() {}

    public function isEmpty():Bool
    {
        return plies.empty();
    }

    public function clear():Void
    {
        plies = [];
    }

    public function add(ply:RawPly):Void
    {
        plies.push(ply);
    }

    /**
        Whether `coords` is the departure or the destination of any queued premove.
    **/
    public function touches(coords:HexCoords):Bool
    {
        return plies.exists(p -> p.from.equals(coords) || p.to.equals(coords));
    }

    /**
        The departure and destination hexes of every queued premove, for highlighting.
    **/
    public function hexes():Array<HexCoords>
    {
        var result:Array<HexCoords> = [];
        for (ply in plies)
        {
            result.push(ply.from);
            result.push(ply.to);
        }
        return result;
    }

    /**
        `position` as it would be after every queued premove - `position` itself, untouched, when
        the queue is empty; otherwise a copy.
    **/
    public function applyTo(position:Position):Position
    {
        if (plies.empty())
            return position;

        var result:Position = position.copy();
        for (ply in plies)
        {
            var piece:Null<PieceData> = result.getPiece(ply.from);
            if (piece == null)  // The real position changed under it; it'll fail validation when its turn comes
                continue;

            result.set(ply.from, Empty);
            result.set(ply.to, Occupied(new PieceData(ply.morphInto != null ? ply.morphInto : piece.type, piece.color)));
        }
        return result;
    }

    /**
        Removes the first premove and returns it as it would be played in `position` by `color`,
        or returns `null` - emptying the whole queue - if it can't be played there (or if the queue
        was already empty).
    **/
    public function takeNext(position:Position, color:PieceColor, rules:MoveRules):Null<RawPly>
    {
        if (plies.empty())
            return null;

        var ply:Null<RawPly> = playableForm(plies[0], position, color, rules);
        if (ply == null)
            plies = [];
        else
            plies.shift();
        return ply;
    }

    private static function playableForm(premove:RawPly, position:Position, color:PieceColor, rules:MoveRules):Null<RawPly>
    {
        var piece:Null<PieceData> = position.getPiece(premove.from);
        if (piece == null || piece.color != color)
            return null;
        if (!rules.getLegalDestinations(premove.from, position.pieces).exists(h -> h.equals(premove.to)))
            return null;

        // The promotion was picked back when queued; whether it's needed is only known now.
        if (rules.isPromotionPossible(piece, premove.to))
            return premove.morphInto != null ? premove : null;
        return RawPly.construct(premove.from, premove.to);
    }
}
