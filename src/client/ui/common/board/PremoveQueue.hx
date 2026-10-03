package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;

using Lambda;

private typedef QueuedPremove =
{
    // Its `morphInto` is the promotion choice.
    ply:RawPly,
    // The chameleon choice: the kind to morph into on capture, the piece's own kind for "don't", `null` if never asked.
    chameleon:Null<PieceKind>
}

/**
    The premoves a user has planned, in the order they'll be played. Pure data and rules - no
    board, no events - so `Premoves` can drive it and a test can too.

    Nothing is checked when a premove is `add`ed: it's only a plan. `applyTo` shows what the board
    would look like if all of them had been played (a bare transposition of pieces, so the same
    piece can be premoved again from its destination), and `takeNext` is where a premove is finally
    validated - only the first one, against the position it would really be played in; if it
    fails, the whole queue goes with it.
**/
class PremoveQueue
{
    private var premoves:Array<QueuedPremove> = [];

    public function new() {}

    public function isEmpty():Bool
    {
        return premoves.empty();
    }

    public function clear():Void
    {
        premoves = [];
    }

    /**
        Queues `ply` (its `morphInto` being the promotion choice). `chameleon`: the kind to morph
        into if it captures, the moving piece's own kind to never morph, `null` if never asked
        (no morph either).
    **/
    public function add(ply:RawPly, chameleon:Null<PieceKind>):Void
    {
        premoves.push({ply: ply, chameleon: chameleon});
    }

    /**
        The departure and destination hexes of every queued premove, for highlighting.
    **/
    public function hexes():Array<HexCoords>
    {
        var result:Array<HexCoords> = [];
        for (premove in premoves)
        {
            result.push(premove.ply.from);
            result.push(premove.ply.to);
        }
        return result;
    }

    /**
        `position` as it would be after every queued premove - `position` itself, untouched, when
        the queue is empty; otherwise a copy. A chameleon choice shows as the morph.
    **/
    public function applyTo(position:Position):Position
    {
        if (premoves.empty())
            return position;

        var result:Position = position.copy();
        for (premove in premoves)
        {
            var piece:Null<PieceData> = result.getPiece(premove.ply.from);
            if (piece == null)  // The real position changed under it; it'll fail validation when its turn comes
                continue;

            var kind:PieceKind = premove.ply.morphInto ?? premove.chameleon ?? piece.type;
            result.set(premove.ply.from, Empty);
            result.set(premove.ply.to, Occupied(new PieceData(kind, piece.color)));
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
        if (premoves.empty())
            return null;

        var ply:Null<RawPly> = playableForm(premoves[0], position, color, rules);
        if (ply == null)
            premoves = [];
        else
            premoves.shift();
        return ply;
    }

    private static function playableForm(premove:QueuedPremove, position:Position, color:PieceColor, rules:MoveRules):Null<RawPly>
    {
        var from:HexCoords = premove.ply.from;
        var to:HexCoords = premove.ply.to;

        var piece:Null<PieceData> = position.getPiece(from);
        if (piece == null || piece.color != color)
            return null;
        if (!rules.getLegalDestinations(from, position.pieces).exists(h -> h.equals(to)))
            return null;

        // The promotion was picked back when queued; whether it's needed is only known now.
        if (rules.isPromotionPossible(piece, to))
            return premove.ply.morphInto != null ? premove.ply : null;

        // Morphing into another kind was asked for: only that exact morph will do, nothing else.
        if (premove.chameleon != null && premove.chameleon != piece.type)
        {
            var captured:Null<PieceData> = position.getPiece(to);
            var morphPossible:Bool = captured != null
                && captured.type == premove.chameleon
                && rules.isChameleonPossible(piece, from, captured, position.pieces);
            return morphPossible ? RawPly.construct(from, to, premove.chameleon) : null;
        }

        return RawPly.construct(from, to);
    }
}
