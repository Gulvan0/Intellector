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
    // null: anywhere
    destinations:Null<Array<HexCoords>>
}

private enum ToolState
{
    Idle;
    Selected(picked:PickedPiece);
    Dragging(picked:PickedPiece);
    // A choice completing the move is pending in `prompt`; the moving piece is drawn on `to`.
    AwaitingChoice(picked:PickedPiece, to:HexCoords, prompt:MovePrompt);
}

private typedef HexTintPlacement =
{
    hex:HexCoords,
    tint:HexTint
}

/**
    Picking up pieces and putting them down - by dragging, or by clicking the piece and then its
    destination - on the button it's bound to. What may be picked up and where it may go is the
    policy's; the result is reported as an intent (`playMove`, `PremoveIntent.Queue` or
    `EditIntent.MovePiece`, by the mode the policy gives) and never applied by the tool itself.

    Shows the feedback of a gesture in flight: hover, selection and prompt anchor tints, move
    markers, the dragged piece, and the promotion/chameleon prompt that completes a move, during
    which the board's gestures are suspended.

    Reads the shown position off the board. On a `Move`, a selection or drag survives if the same
    piece still stands on its departure and the policy still lets it be picked up; anything else
    aborts it. An open prompt is closed (dropping that move), unless it completes a premove and
    the policy keeps it open across the move (other premoves still queued) with the piece still
    on its departure. Also reports
    `PremoveIntent.CancelAll` for presses and Esc that mean it while nothing is picked up.
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

    // Under the mouse cursor (hover events).
    private var hoveredHex:Null<HexCoords> = null;
    // Under the pointer dragging a piece, and where exactly.
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
        Starts reacting to presses, drags and releases of `button` on `gestures`, plus hover and
        Esc. Detaching the returned handle aborts any gesture in flight. One binding at a time.
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

    /**
        Aborts any gesture in flight, prompt included, and applies `policy` from then on.
    **/
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
                // A second press can't start before the first one's release; prompts suspend the gestures.
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

                // Released where it was picked up: a click, which selects the piece.
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
                // A click on a destination completes the move on its press.
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
                // The prompt handles its own Esc.
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

    /*
        Whether a pending premove choice stays open across a move: while the policy says so (other
        premoves are still queued), the premove's piece is still on its departure and the policy
        still has it premoved.
    */
    private function keepsChoice(picked:PickedPiece):Bool
    {
        if (picked.mode != Premove || !policy.keepsChoiceAcrossMove(board.getPosition()))
            return false;

        var repicked:Null<PickedPiece> = repick(picked);
        return repicked != null && repicked.mode == Premove;
    }

    /*
        The piece picked up before a move came in, as it can be held on to in the new position:
        the same piece still on its departure, and the policy (asked again) still letting it be
        picked up. `null` if it can't.
    */
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

    // Starts dragging the piece on `hex`, if it can be picked up. Returns whether it was.
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

    /*
        `morphInto`: the promotion or (for a move) chameleon choice; `chameleon`: a premove's
        chameleon choice.
    */
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

    // The board shows the move as though made while the choice is pending: the piece on the anchor hex, a captured one gone.
    private function awaitChoice(picked:PickedPiece, to:HexCoords, prompt:MovePrompt):Void
    {
        showChoice(picked.from, to);
        tints.add(PromptAnchor, to);

        if (gestures != null)
            suspension = gestures.suspend();

        state = AwaitingChoice(picked, to, prompt);
        refreshHover();
    }

    // The moving piece drawn on the anchor, whatever stands there hidden (redone after a new position).
    private function showChoice(from:HexCoords, to:HexCoords):Void
    {
        board.movePieceToHex(from, to);
        board.setPieceVisible(to, false);
    }

    // Closes the pending choice's prompt (if still open) and undoes what awaitChoice showed.
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

    // Back to Idle, undoing whatever the gesture in flight showed. Reports nothing.
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
                // Touch has no hover: the pointer's own position while dragging counts.
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
