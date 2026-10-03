package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import morestd.Signal;

/**
    The premove queue of a live game, sitting between the real position and the board: shows the
    real position with the queued premoves already played (tinted `Premove`), and fires the first
    one through `playMove` when the user's turn comes.

    Obeys `PremoveIntent`s. Drops the queue on a `Replacement`, when disabled, on `clear` (game
    end), when the premove to fire turns out to be impossible.
**/
class Premoves
{
    private final board:BoardSurface;
    private final tints:HexTints;
    private final rules:MoveRules;
    private final userColor:PieceColor;
    private final playMove:Signal<RawPly>;
    private final intentsHandle:Detachable;

    private final queue:PremoveQueue = new PremoveQueue();
    private var realPosition:Position;
    private var enabled:Bool;

    // Incremented on every setRealPosition, to tell whether firing a premove brought a new one in.
    private var realPositionVersion:Int = 0;

    public function new(board:BoardSurface, tints:HexTints, rules:MoveRules, userColor:PieceColor, realPosition:Position, enabled:Bool, playMove:Signal<RawPly>, intents:Signal<PremoveIntent>)
    {
        this.board = board;
        this.tints = tints;
        this.rules = rules;
        this.userColor = userColor;
        this.realPosition = realPosition;
        this.enabled = enabled;
        this.playMove = playMove;

        intentsHandle = intents.subscribe(onIntent);
    }

    /**
        Stops obeying intents and drops the queue, leaving the board showing the real position.
    **/
    public function dispose():Void
    {
        intentsHandle.detach();
        clear();
    }

    /**
        Whose turn it is in the real position (the shown one may differ, with premoves queued).
    **/
    public function realTurn():PieceColor
    {
        return realPosition.turnColor;
    }

    /**
        Whether any premove is queued.
    **/
    public function hasQueued():Bool
    {
        return !queue.isEmpty();
    }

    public function isEnabled():Bool
    {
        return enabled;
    }

    public function setEnabled(enabled:Bool):Void
    {
        this.enabled = enabled;
        if (!enabled)
            clear();
    }

    /**
        Drops every queued premove.
    **/
    public function clear():Void
    {
        if (queue.isEmpty())
            return;

        queue.clear();
        show(PremovesChanged);
    }

    /**
        The real position changed. On a `Move` that hands the turn to the user, the first queued
        premove is fired through `playMove` - whose handler is expected to call this again with the
        position after it - or the whole queue dropped if it can't be played.
    **/
    public function setRealPosition(position:Position, cause:PositionChangeCause):Void
    {
        realPositionVersion++;
        realPosition = position;

        if (cause == Replacement)
            queue.clear();
        else if (cause == Move && position.turnColor == userColor && !queue.isEmpty())
        {
            var ply:Null<RawPly> = queue.takeNext(position, userColor, rules);
            if (ply != null)
            {
                var version:Int = realPositionVersion;
                playMove.dispatch(ply);

                // The handler already showed the position after the fired premove.
                if (realPositionVersion != version)
                    return;
            }
        }

        show(cause);
    }

    private function onIntent(intent:PremoveIntent):Void
    {
        switch intent
        {
            case Queue(ply, morphInto):
                if (!enabled)
                    return;
                queue.add(ply, morphInto);
                show(PremovesChanged);
            case CancelAll:
                clear();
        }
    }

    private function show(cause:PositionChangeCause):Void
    {
        board.setPosition(queue.applyTo(realPosition), cause);
        tints.set(Premove, queue.hexes());
    }
}
