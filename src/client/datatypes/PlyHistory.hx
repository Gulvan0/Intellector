package client.datatypes;

import client.ui.common.board.PositionChangeCause;
import intellectorboard.plyapplication.PlyPerformer;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import morestd.Signal;

/**
    What a history wants a board to show.
**/
typedef ShownPly =
{
    position:Position,
    // The ply that led to `position`; `null` at the starting position.
    lastMove:Null<RawPly>,
    cause:PositionChangeCause
}

/**
    A game's linear history of plies, and which of its positions is shown. Owned by a page; tells
    it, through `onShownChanged`, what the board should show: a `Move` cause when the shown position
    advances by exactly the new ply, `Replacement` for any other jump.
**/
class PlyHistory
{
    /**
        Dispatched whenever the shown position changes.
    **/
    public final onShownChanged:Signal<ShownPly> = new Signal();

    private final plies:Array<RawPly> = [];
    // positions[k] is the position after k plies; positions[0] is the starting one.
    private final positions:Array<Position>;
    // How many plies the shown position is after.
    private var shownPlyCount:Int = 0;

    public function new(startingPosition:Position)
    {
        positions = [startingPosition];
    }

    public function plyCount():Int
    {
        return plies.length;
    }

    /**
        How many plies the shown position is after (0 for the starting position).
    **/
    public function shownPlyIndex():Int
    {
        return shownPlyCount;
    }

    public function isShowingLatest():Bool
    {
        return shownPlyCount == plies.length;
    }

    public function latestPosition():Position
    {
        return positions[plies.length];
    }

    public function shownPosition():Position
    {
        return positions[shownPlyCount];
    }

    /**
        Adds `ply` to the end of the history. The view follows it if it was showing the latest
        position (as a `Move`), or if `followLatestMove` (snapping back from an older position, as
        a `Replacement`); otherwise the shown position stays as it is.
    **/
    public function append(ply:RawPly, followLatestMove:Bool):Void
    {
        var wasShowingLatest:Bool = isShowingLatest();

        plies.push(ply);
        positions.push(PlyPerformer.positionAfterRawPly(positions[positions.length - 1], ply));

        if (wasShowingLatest)
            show(plies.length, Move);
        else if (followLatestMove)
            show(plies.length, Replacement);
    }

    public function navigate(type:PlyNavigationType):Void
    {
        var target:Int = switch type {
            case Start: 0;
            case Previous: shownPlyCount - 1;
            case Next: shownPlyCount + 1;
            case End: plies.length;
            case AfterPly(index): index + 1;
        }

        if (target < 0)
            target = 0;
        if (target > plies.length)
            target = plies.length;

        if (target != shownPlyCount)
            show(target, Replacement);
    }

    /**
        Whether `mode` asks the view to snap back to a new move in a game the user `isPlaying` or not.
    **/
    public static function followsLatestMove(mode:FollowLatestMoveMode, isPlaying:Bool):Bool
    {
        return switch mode {
            case ALWAYS: true;
            case OWN_GAME_ONLY: isPlaying;
            case NEVER: false;
        }
    }

    private function show(plyCount:Int, cause:PositionChangeCause):Void
    {
        shownPlyCount = plyCount;
        onShownChanged.dispatch({
            position: positions[plyCount],
            lastMove: plyCount > 0 ? plies[plyCount - 1] : null,
            cause: cause
        });
    }
}
