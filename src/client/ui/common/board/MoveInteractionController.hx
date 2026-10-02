package client.ui.common.board;

import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.Hex;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.ply.RawPly;
import client.ui.common.board.move_prompt.MovePrompt;
import js.Browser;
import js.html.PointerEvent;

using Lambda;

private enum InteractionState
{
    Idle;
    Selected(from:HexCoords);
    Dragging(from:HexCoords);
    // The move's promotion/chameleon choice is pending in `prompt`; the moving piece is drawn on `to`.
    AwaitingChoice(from:HexCoords, to:HexCoords, prompt:MovePrompt);
}

/**
    Click/drag-to-move on a `BoardSurface`: its own idle/selected/dragging mini-state, not a
    swappable polymorphic behavior (see knowledge/plans/board_plan.md), plus the premove queue.
    RMB annotations are a separate, not-yet-built controller; this one owns left-button gestures
    only.

    Premoves: while `config.premovesEnabled` and it isn't `config.allowedToMove`'s turn (read off
    the position), the same gestures queue premoves (geometry-only destinations, no markers; a
    promotion is chosen up front, a chameleon never is) instead of calling `onMoveChosen`. A queued premove is drawn as
    though already played - the piece stands on its destination, from where it can be premoved
    again (a bare transposition of pieces; nothing is checked). Nothing is validated until
    the turn comes to `allowedToMove` (a `notifyMovePlayed` call) - then the queue's first premove
    is played through `onMoveChosen` if it's still legal, and the whole queue is dropped if it
    isn't. Clicking a hex that starts no gesture also drops the queue, as does any position change
    that isn't a move being played (`notifyPositionReplaced`; `notifyMovePlayed` keeps it) and any
    config change of `allowedToMove` or to `premovesEnabled = false`.

    Mandatory interruption contract: `notifyMovePlayed`/`notifyPositionReplaced`/`notifyConfigChanged`
    always cleanly abort a gesture in flight - the page must call one of the first two, then the
    last, whenever the position or the config changes for any reason (a move by either side, a
    rollback, leaving the page), not just in response to this controller's own `onMoveChosen`.
    Call `board.setPosition` first, then the position notification: a queued premove is resolved
    there, against the position it carries.
**/
class MoveInteractionController
{
    private final board:BoardSurface;
    private final rules:MoveRules;
    private final onMoveChosen:RawPly->Void;

    // The real position, as last reported by the page.
    private var position:Position;
    // `position` with the queued premoves transposed onto it - what's drawn and what gestures work on.
    private var shownPosition:Position;
    private var config:MoveInteractionConfig;

    private var state:InteractionState = Idle;
    private var legalDestinations:Array<HexCoords> = [];
    private var premoves:Array<RawPly> = [];
    private var markers:Array<SVGCircleBuilder> = [];
    private var hoveredHex:Null<HexCoords> = null;

    public function new(board:BoardSurface, position:Position, rules:MoveRules, config:MoveInteractionConfig, onMoveChosen:RawPly->Void)
    {
        this.board = board;
        this.position = position;
        this.shownPosition = position;
        this.rules = rules;
        this.config = config;
        this.onMoveChosen = onMoveChosen;

        // Native window-level listeners: clientX/clientY are scroll- and transform-safe against
        // BoardSurface's getBoundingClientRect(), unlike HaxeUI's MouseEvent.screenX/Y.
        Browser.window.addEventListener("pointerdown", onMouseDown);
        Browser.window.addEventListener("pointermove", onMouseMove);
        Browser.window.addEventListener("pointerup", onMouseUp);
    }

    /**
        Releases this controller's global mouse listeners and cleans up any gesture in flight.
        Call once, when the board this controller is attached to goes away.
    **/
    public function dispose():Void
    {
        abortGesture();

        Browser.window.removeEventListener("pointerdown", onMouseDown);
        Browser.window.removeEventListener("pointermove", onMouseMove);
        Browser.window.removeEventListener("pointerup", onMouseUp);
    }

    /**
        Must be called every time the page also calls `board.setPosition` because a move was played,
        by either side (including one this controller reported through `onMoveChosen`): keeps this
        controller's own view of the position in sync and aborts any gesture in flight. Queued
        premoves stay - a move is the one thing they're planned across - and if the turn has now
        come to `allowedToMove`, the first of them is played (or the queue dropped, if it can't be).
    **/
    public function notifyMovePlayed(position:Position):Void
    {
        abortGesture();
        this.position = position;
        this.shownPosition = position;

        if (isUsersTurn())
            resolvePremoves();
        else if (!premoves.empty())
            refreshPremoveDisplay();
    }

    /**
        Same as `notifyMovePlayed`, for the position changing for any other reason - a rollback,
        history navigation, a reset - and so also discards every queued premove: they were planned
        against a position that's gone.
    **/
    public function notifyPositionReplaced(position:Position):Void
    {
        abortGesture();
        this.position = position;
        this.shownPosition = position;
        premoves = [];
    }

    /**
        Must be called whenever the config changes for any reason (started/stopped spectating,
        started browsing history, the premove preference toggled). Aborts any gesture in flight.
    **/
    public function notifyConfigChanged(config:MoveInteractionConfig):Void
    {
        abortGesture();

        var dropPremoves:Bool = config.allowedToMove != this.config.allowedToMove || !config.premovesEnabled;
        this.config = config;

        if (dropPremoves)
            setPremoves([]);
    }

    private function onMouseDown(e:PointerEvent):Void
    {
        if (e.button != 0)
            return;

        var target:Null<HexCoords> = board.hexAtClientPoint(e.clientX, e.clientY);

        switch state
        {
            case Idle:
                tryBeginDraggingOrDropPremoves(target);

            case Selected(from):
                if (target != null && target.equals(from))
                    abortGesture();
                else if (target != null && legalDestinations.exists(h -> h.equals(target)))
                    attemptMove(from, target);
                else
                {
                    abortGesture();
                    tryBeginDraggingOrDropPremoves(target);
                }

            case Dragging(_):
                // A second mouse-down can't happen before the first's mouse-up; ignore.

            case AwaitingChoice(_, _, _):
                // The board is inert until the popover's choice is made (or the gesture is interrupted).
        }
    }

    private function onMouseMove(e:PointerEvent):Void
    {
        var target:Null<HexCoords> = board.hexAtClientPoint(e.clientX, e.clientY);

        switch state
        {
            case Idle:
                updateHover(target, isDepartureCandidate, h -> Departure);

            case Selected(_):
                updateHover(target, isLegalDestination, h -> DestinationHover);

            case Dragging(from):
                updateHover(target, isLegalDestination, h -> DestinationHover);
                var boardPoint = board.clientPointToBoardPoint(e.clientX, e.clientY);
                board.movePieceTo(from, boardPoint.x, boardPoint.y);

            case AwaitingChoice(_, _, _):
        }
    }

    private function onMouseUp(e:PointerEvent):Void
    {
        if (e.button != 0)
            return;

        switch state
        {
            case Dragging(from):
                var target:Null<HexCoords> = board.hexAtClientPoint(e.clientX, e.clientY);

                if (target != null && target.equals(from))
                {
                    state = Selected(from);
                    board.resetPiecePosition(from);
                }
                else if (target != null && legalDestinations.exists(h -> h.equals(target)))
                    attemptMove(from, target);
                else
                    abortGesture();

            case Idle, Selected(_), AwaitingChoice(_, _, _):
                // Only a drag's release is meaningful; a plain click is handled on mouse-down.
        }
    }

    private function isUsersTurn():Bool
        return config.allowedToMove != null && position.turnColor == config.allowedToMove;

    private function isPremoveMode():Bool
        return config.premovesEnabled && config.allowedToMove != null && !isUsersTurn();

    // The color whose pieces a gesture may pick up right now.
    private function movableColor():Null<PieceColor>
        return isUsersTurn() || isPremoveMode() ? config.allowedToMove : null;

    private function isDepartureCandidate(h:HexCoords):Bool
    {
        var piece:Null<PieceData> = shownPosition.getPiece(h);
        return piece != null && movableColor() != null && piece.color == movableColor();
    }

    private function tryBeginDraggingOrDropPremoves(target:Null<HexCoords>):Void
    {
        tryBeginDragging(target);

        if (state.match(Idle) && target != null)
            setPremoves([]);
    }

    private function tryBeginDragging(target:Null<HexCoords>):Void
    {
        if (target == null || !isDepartureCandidate(target))
            return;

        var premoving:Bool = isPremoveMode();

        state = Dragging(target);
        legalDestinations = premoving ? rules.getPremoveDestinations(target, shownPosition.pieces) : rules.getLegalDestinations(target, shownPosition.pieces);

        // The departure keeps the orange it got as a hover candidate; it's now owned by the
        // gesture (reset in abortGesture), not by hover tracking.
        hoveredHex = null;
        board.setHexTint(target, Departure);
        if (!premoving)
            for (destination in legalDestinations)
                markers.push(board.addMoveMarker(destination));
        board.bringPieceToFront(target);
    }

    private function attemptMove(from:HexCoords, to:HexCoords):Void
    {
        var movingPiece:PieceData = shownPosition.getPiece(from);
        var capturedPiece:Null<PieceData> = shownPosition.getPiece(to);
        var premoving:Bool = isPremoveMode();
        abortGesture();

        if (premoving)
        {
            // The chameleon choice depends on a capture that may never happen - never asked for a premove.
            if (rules.isPromotionPossible(movingPiece, to))
            {
                awaitChoice(from, to, capturedPiece, MovePrompt.promotion(board, to, movingPiece.color, kind -> {
                    abortGesture();
                    setPremoves(premoves.concat([RawPly.construct(from, to, kind)]));
                }, abortGesture));
            }
            else
                setPremoves(premoves.concat([RawPly.construct(from, to)]));
        }
        else if (rules.isPromotionPossible(movingPiece, to))
        {
            awaitChoice(from, to, capturedPiece, MovePrompt.promotion(board, to, movingPiece.color, kind -> {
                abortGesture();
                onMoveChosen(RawPly.construct(from, to, kind));
            }, abortGesture));
        }
        else if (rules.isChameleonPossible(movingPiece, from, capturedPiece, shownPosition.pieces))
        {
            awaitChoice(from, to, capturedPiece, MovePrompt.captureMorph(board, to, movingPiece.type, movingPiece.color, capturedPiece.type, chameleon -> {
                abortGesture();
                onMoveChosen(RawPly.construct(from, to, chameleon ? capturedPiece.type : null));
            }, abortGesture));
        }
        else
            onMoveChosen(RawPly.construct(from, to));
    }

    // The board stays as it is, but shows the move as though made: the piece on the anchor hex, the captured one gone.
    private function awaitChoice(from:HexCoords, to:HexCoords, capturedPiece:Null<PieceData>, prompt:MovePrompt):Void
    {
        board.movePieceToHex(from, to);
        if (capturedPiece != null)
            board.setPieceVisible(to, false);
        board.setHexTint(to, PromptAnchor);

        state = AwaitingChoice(from, to, prompt);
    }

    private function isLegalDestination(h:HexCoords):Bool
        return legalDestinations.exists(x -> x.equals(h));

    private function isPremoveHex(h:HexCoords):Bool
        return premoves.exists(p -> p.from.equals(h) || p.to.equals(h));

    // Back to what the hex shows when no gesture is touching it: the premove tint, or the base fill.
    private function restoreHexFill(h:HexCoords):Void
    {
        if (isPremoveHex(h))
            board.setHexTint(h, Premove);
        else
            board.resetHexFill(h);
    }

    private function paintPremoves():Void
    {
        for (premove in premoves)
            for (h in [premove.from, premove.to])
                board.setHexTint(h, Premove);
    }

    // Only called with no gesture in flight, so there's no gesture-owned drawing for the redraw to wipe.
    private function setPremoves(newPremoves:Array<RawPly>):Void
    {
        var changed:Bool = !premoves.empty() || !newPremoves.empty();
        premoves = newPremoves;

        if (changed)
            refreshPremoveDisplay();
    }

    // Rebuilds `shownPosition` from the real position and the queue, then redraws the board from it.
    private function refreshPremoveDisplay():Void
    {
        shownPosition = position;

        if (!premoves.empty())
        {
            shownPosition = position.copy();
            for (premove in premoves)
            {
                var piece:Null<PieceData> = shownPosition.getPiece(premove.from);
                if (piece == null)  // The real position changed under it; it'll fail validation when its turn comes
                    continue;

                shownPosition.set(premove.from, Empty);
                shownPosition.set(premove.to, Occupied(new PieceData(premove.morphInto != null ? premove.morphInto : piece.type, piece.color)));
            }
        }

        board.setPosition(shownPosition);
        paintPremoves();
    }

    private function resolvePremoves():Void
    {
        if (premoves.empty())
            return;

        var ply:Null<RawPly> = currentlyLegalForm(premoves[0]);
        setPremoves(ply != null ? premoves.slice(1) : []);

        if (ply != null)
            onMoveChosen(ply);
    }

    // `premove` as it would be played in the current position, or `null` if it can't be.
    private function currentlyLegalForm(premove:RawPly):Null<RawPly>
    {
        var piece:Null<PieceData> = position.getPiece(premove.from);
        if (piece == null || piece.color != config.allowedToMove)
            return null;
        if (!rules.getLegalDestinations(premove.from, position.pieces).exists(h -> h.equals(premove.to)))
            return null;

        // The promotion was picked back when queued; whether it's needed is only known now.
        if (rules.isPromotionPossible(piece, premove.to))
            return premove.morphInto != null ? premove : null;
        return RawPly.construct(premove.from, premove.to);
    }

    private function updateHover(target:Null<HexCoords>, isReactive:HexCoords->Bool, tintOf:HexCoords->HexTint):Void
    {
        if (HexCoords.areEqual(target, hoveredHex))
            return;

        if (hoveredHex != null)
            restoreHexFill(hoveredHex);

        hoveredHex = (target != null && isReactive(target)) ? target : null;

        if (hoveredHex != null)
            board.setHexTint(hoveredHex, tintOf(hoveredHex));
    }

    private function abortGesture():Void
    {
        switch state
        {
            case Selected(from):
                restoreHexFill(from);
            case Dragging(from):
                restoreHexFill(from);
                board.resetPiecePosition(from);
            case AwaitingChoice(from, to, prompt):
                prompt.close();
                restoreHexFill(to);
                board.setPieceVisible(to, true);
                board.resetPiecePosition(from);
            case Idle:
        }

        for (marker in markers)
            marker.element.remove();
        markers = [];
        legalDestinations = [];

        if (hoveredHex != null)
            restoreHexFill(hoveredHex);
        hoveredHex = null;

        state = Idle;
    }
}
