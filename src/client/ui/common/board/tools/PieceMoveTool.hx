package client.ui.common.board.tools;

import client.ui.common.board.BoardInputOptions;
import client.ui.common.board.BoardPoint;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.EditIntent;
import client.ui.common.board.HexTint;
import client.ui.common.board.HexTints;
import client.ui.common.board.PositionChangeCause;
import client.ui.common.board.PremoveIntent;
import client.ui.common.board.input.BoardGestures;
import client.ui.common.board.input.HexDrag;
import client.ui.common.board.input.HexPress;
import client.ui.common.board.input.Modifiers;
import client.ui.common.board.input.PointerButton;
import client.ui.common.board.move_prompt.MovePrompt;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import morestd.Signal;

using Lambda;

private typedef PickedPiece =
{
    from:HexCoords,
    piece:PieceData,
    mode:PieceMoveMode,
    // `null` for anywhere
    destinations:Null<Array<HexCoords>>
}

private enum ToolState
{
    Idle;
    Selected(picked:PickedPiece);
    Dragging(picked:PickedPiece);
    /** A choice completing the move is pending in `prompt`; the moving piece is drawn on `to` **/
    AwaitingChoice(picked:PickedPiece, to:HexCoords, prompt:MovePrompt);
}

private typedef HexTintPlacement =
{
    hex:HexCoords,
    tint:HexTint
}

/**
    Moving pieces by dragging, or by clicking the piece and then its destination, as the policy
    allows. Only reports the result (`playMove`, `PremoveIntent` or `EditIntent`, by mode), showing
    the gesture's tints, markers and completing prompt meanwhile.

    On a `Move`, a selection or drag survives if the same piece still stands on its departure and
    can still be picked up; an open prompt survives only per `keepsChoiceAcrossMove`.
**/
class PieceMoveTool
{
    private final board:BoardSurface;
    private final tints:HexTints;
    private final options:BoardInputOptions;
    private var policy:PieceMovePolicy;

    private final playMove:Signal<RawPly>;
    private final premoveIntents:Signal<PremoveIntent>;
    private final editIntents:Signal<EditIntent>;

    private final positionHandle:Detachable;

    private var gestures:Null<BoardGestures> = null;
    private var bindingHandles:Array<Detachable> = [];
    private var suspension:Null<Detachable> = null;

    private var state:ToolState = Idle;

    // under the mouse cursor
    private var hoveredHex:Null<HexCoords> = null;
    // under the pointer dragging a piece
    private var dragHex:Null<HexCoords> = null;
    private var dragPoint:Null<BoardPoint> = null;

    private var hoverTint:Null<HexTintPlacement> = null;

    public function new(board:BoardSurface, tints:HexTints, options:BoardInputOptions, policy:PieceMovePolicy, playMove:Signal<RawPly>, premoveIntents:Signal<PremoveIntent>, editIntents:Signal<EditIntent>)
    {
        this.board = board;
        this.tints = tints;
        this.options = options;
        this.policy = policy;
        this.playMove = playMove;
        this.premoveIntents = premoveIntents;
        this.editIntents = editIntents;

        positionHandle = board.onPositionChanged.subscribe(onPositionChanged);
    }

    /**
        Starts moving pieces with `button`; detaching the handle aborts the gesture in flight. One
        binding at a time.
    **/
    public function bind(gestures:BoardGestures, button:PointerButton):Detachable
    {
        unbind();

        this.gestures = gestures;
        bindingHandles = [
            gestures.onHoverChanged(onHoverChanged),
            gestures.onPress(button, onPress),
            gestures.onDragMove(button, onDragMove),
            gestures.onRelease(button, onRelease),
            gestures.onEscape(onEscape)
        ];

        return new Detachable(unbind, false);
    }

    /** Aborts the gesture in flight and applies `policy` from then on **/
    public function setPolicy(policy:PieceMovePolicy):Void
    {
        abort();
        this.policy = policy;
        refreshHover();
    }

    public function dispose():Void
    {
        unbind();
        positionHandle.detach();
    }

    private function unbind():Void
    {
        abort();
        clearHoverTint();
        hoveredHex = null;

        for (handle in bindingHandles)
            handle.detach();
        bindingHandles = [];
        gestures = null;
    }

    private function onHoverChanged(hex:Null<HexCoords>):Void
    {
        hoveredHex = hex;
        refreshHover();
    }

    private function onPress(press:HexPress):Void
    {
        var hex:Null<HexCoords> = press.hex;

        switch state
        {
            case Idle:
                if (!tryPickUp(hex))
                    premoveIntents.dispatch(CancelAll);

            case Selected(picked):
                if (hex == null || hex.equals(picked.from))
                    abort();
                else if (isDestination(picked, hex))
                    complete(picked, hex, press.modifiers);
                else
                {
                    abort();
                    tryPickUp(hex);
                }

            case Dragging(_), AwaitingChoice(_, _, _):
                // no press before the first one's release; prompts suspend the gestures
        }
    }

    private function onDragMove(drag:HexDrag):Void
    {
        switch state
        {
            case Dragging(picked):
                dragHex = drag.hex;
                dragPoint = drag.point;
                board.movePieceToPoint(picked.from, drag.point);
                refreshHover();
            default:
        }
    }

    private function onRelease(release:HexPress):Void
    {
        var hex:Null<HexCoords> = release.hex;

        switch state
        {
            case Dragging(picked):
                dragHex = null;
                dragPoint = null;

                // released where picked up: a click, selecting the piece
                if (hex != null && hex.equals(picked.from))
                {
                    state = Selected(picked);
                    board.resetPiece(picked.from);
                    refreshHover();
                }
                else if (isDestination(picked, hex))
                    complete(picked, hex, release.modifiers);
                else
                    abort();

            default:
                // a click on a destination completes the move on its press
        }
    }

    private function onEscape():Void
    {
        switch state
        {
            case Idle:
                premoveIntents.dispatch(CancelAll);
            case Selected(_), Dragging(_):
                abort();
            case AwaitingChoice(_, _, _):
                // the prompt handles its own Esc
        }
    }

    private function onPositionChanged(cause:PositionChangeCause):Void
    {
        switch state
        {
            case Selected(picked):
                var resumed:Null<PickedPiece> = cause == Move ? repick(picked) : null;
                if (resumed == null)
                    abort();
                else
                {
                    state = Selected(resumed);
                    showMarkers(resumed);
                }

            case Dragging(picked):
                var resumed:Null<PickedPiece> = cause == Move ? repick(picked) : null;
                if (resumed == null)
                    abort();
                else
                {
                    state = Dragging(resumed);
                    showMarkers(resumed);
                    if (dragPoint != null)
                        board.movePieceToPoint(resumed.from, dragPoint);
                }

            case AwaitingChoice(picked, to, _):
                if (cause == Move && keepsChoice(picked))
                    showChoice(picked.from, to);
                else
                    abort();

            case Idle:
        }

        refreshHover();
    }

    // while the policy allows it and the piece is still on its departure, still premoved
    private function keepsChoice(picked:PickedPiece):Bool
    {
        if (picked.mode != Premove || !policy.keepsChoiceAcrossMove(board.getPosition()))
            return false;

        var repicked:Null<PickedPiece> = repick(picked);
        return repicked != null && repicked.mode == Premove;
    }

    // the same piece, still on its departure and still allowed to be picked up; `null` otherwise
    private function repick(picked:PickedPiece):Null<PickedPiece>
    {
        var position:Position = board.getPosition();
        var piece:Null<PieceData> = position.getPiece(picked.from);
        if (piece == null || !piece.equals(picked.piece))
            return null;

        var mode:Null<PieceMoveMode> = policy.pickMode(position);
        if (mode == null || !policy.canPickUp(position, mode, picked.from))
            return null;

        return {
            from: picked.from,
            piece: piece,
            mode: mode,
            destinations: policy.destinations(position, mode, picked.from)
        };
    }

    // returns whether the piece on `hex` could be picked up
    private function tryPickUp(hex:Null<HexCoords>):Bool
    {
        if (hex == null)
            return false;

        var position:Position = board.getPosition();
        var mode:Null<PieceMoveMode> = policy.pickMode(position);
        if (mode == null || !policy.canPickUp(position, mode, hex))
            return false;

        var picked:PickedPiece = {
            from: hex,
            piece: position.getPiece(hex),
            mode: mode,
            destinations: policy.destinations(position, mode, hex)
        };

        state = Dragging(picked);
        tints.add(SelectedDeparture, hex);
        showMarkers(picked);
        refreshHover();
        return true;
    }

    private function showMarkers(picked:PickedPiece):Void
    {
        board.clearMoveMarkers();

        if (picked.destinations != null && policy.showsMarkers(picked.mode))
            for (destination in picked.destinations)
                board.addMoveMarker(destination);
    }

    private function isDestination(picked:PickedPiece, hex:Null<HexCoords>):Bool
    {
        if (hex == null || hex.equals(picked.from))
            return false;
        return picked.destinations == null || picked.destinations.exists(destination -> destination.equals(hex));
    }

    private function complete(picked:PickedPiece, to:HexCoords, modifiers:Modifiers):Void
    {
        var from:HexCoords = picked.from;
        var mode:PieceMoveMode = picked.mode;
        var completion:CompletionKind = policy.completion(board.getPosition(), mode, from, to);

        abort();

        switch completion
        {
            case None:
                report(mode, from, to, null, null);

            case Promotion:
                if (options.autoPromotes(modifiers))
                    report(mode, from, to, Dominator, null);
                else
                {
                    awaitChoice(picked, to, MovePrompt.promotion(board, to, picked.piece.color, kind -> {
                        closeChoice();
                        report(mode, from, to, kind, null);
                    }, closeChoice));
                }

            case Chameleon(capturedKind):
                awaitChoice(picked, to, MovePrompt.captureMorph(board, to, picked.piece.type, picked.piece.color, capturedKind, morph -> {
                    closeChoice();
                    report(mode, from, to, morph ? capturedKind : null, null);
                }, closeChoice));

            case PremoveChameleon:
                if (options.asksChameleon(modifiers))
                {
                    awaitChoice(picked, to, MovePrompt.premoveChameleon(board, to, picked.piece.type, picked.piece.color, kind -> {
                        closeChoice();
                        report(mode, from, to, null, kind);
                    }, closeChoice));
                }
                else
                    report(mode, from, to, null, null);
        }
    }

    // `morphInto` is the promotion or a move's chameleon choice; `chameleon` a premove's
    private function report(mode:PieceMoveMode, from:HexCoords, to:HexCoords, morphInto:Null<PieceKind>, chameleon:Null<PieceKind>):Void
    {
        switch mode
        {
            case Move:
                playMove.dispatch(RawPly.construct(from, to, morphInto));
            case Premove:
                premoveIntents.dispatch(Queue(RawPly.construct(from, to, morphInto), chameleon));
            case FreeMove:
                editIntents.dispatch(MovePiece(from, to));
        }
    }

    // the board shows the move as made while the choice is pending
    private function awaitChoice(picked:PickedPiece, to:HexCoords, prompt:MovePrompt):Void
    {
        showChoice(picked.from, to);
        tints.add(PromptAnchor, to);

        if (gestures != null)
            suspension = gestures.suspend();

        state = AwaitingChoice(picked, to, prompt);
        refreshHover();
    }

    // the moving piece on the anchor, hiding whatever stands there
    private function showChoice(from:HexCoords, to:HexCoords):Void
    {
        board.movePieceToHex(from, to);
        board.setPieceVisible(to, false);
    }

    // undoes what `awaitChoice` showed
    private function closeChoice():Void
    {
        switch state
        {
            case AwaitingChoice(picked, to, prompt):
                prompt.close();
                tints.remove(PromptAnchor, to);
                board.setPieceVisible(to, true);
                board.resetPiece(picked.from);

                if (suspension != null)
                    suspension.detach();
                suspension = null;

                state = Idle;
                refreshHover();
            default:
        }
    }

    // back to `Idle`, undoing what the gesture showed, reporting nothing
    private function abort():Void
    {
        switch state
        {
            case Selected(picked), Dragging(picked):
                tints.remove(SelectedDeparture, picked.from);
                board.resetPiece(picked.from);
                board.clearMoveMarkers();
                state = Idle;
            case AwaitingChoice(_, _, _):
                closeChoice();
            case Idle:
        }

        dragHex = null;
        dragPoint = null;
        refreshHover();
    }

    private function refreshHover():Void
    {
        var wanted:Null<HexTintPlacement> = wantedHoverTint();

        if (hoverTint != null && wanted != null && hoverTint.hex.equals(wanted.hex) && hoverTint.tint == wanted.tint)
            return;

        clearHoverTint();

        if (wanted != null)
        {
            tints.add(wanted.tint, wanted.hex);
            hoverTint = wanted;
        }
    }

    private function wantedHoverTint():Null<HexTintPlacement>
    {
        switch state
        {
            case Idle:
                if (hoveredHex == null)
                    return null;
                var position:Position = board.getPosition();
                var mode:Null<PieceMoveMode> = policy.pickMode(position);
                return mode != null && policy.canPickUp(position, mode, hoveredHex) ? {hex: hoveredHex, tint: DepartureHover} : null;

            case Selected(picked):
                return isDestination(picked, hoveredHex) ? {hex: hoveredHex, tint: DestinationHover} : null;

            case Dragging(picked):
                // touch has no hover, so the dragging pointer counts
                var hex:Null<HexCoords> = dragHex ?? hoveredHex;
                return isDestination(picked, hex) ? {hex: hex, tint: DestinationHover} : null;

            case AwaitingChoice(_, _, _):
                return null;
        }
    }

    private function clearHoverTint():Void
    {
        if (hoverTint != null)
            tints.remove(hoverTint.tint, hoverTint.hex);
        hoverTint = null;
    }
}
