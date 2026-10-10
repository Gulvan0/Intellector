package client.ui.common.board;

import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import morestd.Signal;

/**
    A live game's premove queue, between the real position and the board: shows the position with
    the queued premoves played (tinted `Premove`) and fires the first one through `playMove` on the
    user's turn. Drops the queue on a `Replacement`, when disabled, or when a premove fails.
**/
class Premoves implements PremoveState
{
    private final board:BoardView;
    private final tints:HexTints;
    private final rules:MoveRules;
    private final userColor:PieceColor;
    private final playMove:Signal<RawPly>;
    private final intentsHandle:Detachable;

    private final queue:PremoveQueue = new PremoveQueue();
    private var realPosition:Position;
    private var enabled:Bool;

    // tells whether firing a premove brought in a new real position
    private var realPositionVersion:Int = 0;

    public function new(board:BoardView, tints:HexTints, rules:MoveRules, userColor:PieceColor, realPosition:Position, enabled:Bool, playMove:Signal<RawPly>, intents:Signal<PremoveIntent>)
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

    /** Stops obeying intents and drops the queue, leaving the board showing the real position **/
    public function dispose():Void
    {
        intentsHandle.detach();
        clear();
    }

    /** Whose turn it is in the real position, not the premove-advanced one **/
    public function realTurn():PieceColor
    {
        return realPosition.turnColor;
    }

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

    public function clear():Void
    {
        if (queue.isEmpty())
            return;

        queue.clear();
        show(PremovesChanged);
    }

    /**
        On a `Move` handing the turn to the user, fires the first premove through `playMove` (whose
        handler calls this again with the resulting position), or drops the queue if it can't be played.
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

                // the handler already showed the position after it
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
