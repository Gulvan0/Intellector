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
    // `morphInto` is the promotion choice
    ply:RawPly,
    // the kind to morph into on capture; the piece's own kind for "don't", `null` if never asked
    chameleon:Null<PieceKind>
}

/**
    The user's planned premoves, in play order; data and rules only. A premove is unchecked until
    `takeNext` validates it against the real position, dropping the whole queue if it fails.
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
        Queues `ply` (`morphInto` is the promotion choice). `chameleon` is the kind to morph into on
        capture, the piece's own kind to never morph, `null` if never asked.
    **/
    public function add(ply:RawPly, chameleon:Null<PieceKind>):Void
    {
        premoves.push({ply: ply, chameleon: chameleon});
    }

    /** The departure and destination hexes of every queued premove, for highlighting **/
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
        `position` after every queued premove, as a bare transposition of pieces: a copy, or
        `position` itself if the queue is empty.
    **/
    public function applyTo(position:Position):Position
    {
        if (premoves.empty())
            return position;

        var result:Position = position.copy();
        for (premove in premoves)
        {
            var piece:Null<PieceData> = result.getPiece(premove.ply.from);
            // the real position changed under it; it fails validation when its turn comes
            if (piece == null)
                continue;

            var kind:PieceKind = premove.ply.morphInto ?? premove.chameleon ?? piece.type;
            result.set(premove.ply.from, Empty);
            result.set(premove.ply.to, Occupied(new PieceData(kind, piece.color)));
        }
        return result;
    }

    /**
        Removes the first premove and returns it as played in `position` by `color`, or `null`,
        emptying the queue, if it can't be played there.
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

        // picked when queued; only now is it known whether it's needed
        if (rules.isPromotionPossible(piece, to))
            return premove.ply.morphInto != null ? premove.ply : null;

        // a morph was asked for: only that exact morph will do
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
