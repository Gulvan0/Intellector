package client.ui.common.board;

import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
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
    swappable polymorphic behavior (see knowledge/plans/board_plan.md). Premove and RMB
    annotations are separate, not-yet-built controllers (knowledge/plans/board_deferred.md items
    1-2); this one owns left-button gestures only.

    Mandatory interruption contract: `notifyPositionChanged`/`notifyConfigChanged` always cleanly
    abort a gesture in flight - the page must call both whenever the position or the allowed-to-
    move color changes for any reason (opponent's move arriving, a rollback, leaving the page),
    not just in response to this controller's own `onMoveChosen`.
**/
class MoveInteractionController
{
    // Orange: a hex that's a departure candidate (hovered) or the departure itself (selected).
    private static inline final DEPARTURE_COLOR:String = "#E56A00";
    // Destination hover: each hex's normal fill with HSL lightness raised by the same 0.08, so the
    // pale/normal difference is uniform across light and dark hexes (BoardSurface.HEX_FILL_*).
    private static inline final DESTINATION_HOVER_LIGHT:String = "#FFE4C8";
    private static inline final DESTINATION_HOVER_DARK:String = "#D9A068";
    // The hex a pending promotion/chameleon prompt is anchored to (theme token accentMuted).
    private static inline final PROMPT_ANCHOR_COLOR:String = "#C79A56";

    private final board:BoardSurface;
    private final rules:MoveRules;
    private final onMoveChosen:RawPly->Void;

    private var position:Position;
    private var config:MoveInteractionConfig;

    private var state:InteractionState = Idle;
    private var legalDestinations:Array<HexCoords> = [];
    private var markers:Array<SVGCircleBuilder> = [];
    private var hoveredHex:Null<HexCoords> = null;

    public function new(board:BoardSurface, position:Position, rules:MoveRules, config:MoveInteractionConfig, onMoveChosen:RawPly->Void)
    {
        this.board = board;
        this.position = position;
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
        Must be called every time the page also calls `board.setPosition` - keeps this
        controller's own view of the position in sync and aborts any gesture in flight.
    **/
    public function notifyPositionChanged(position:Position):Void
    {
        abortGesture();
        this.position = position;
    }

    /**
        Must be called whenever the allowed-to-move color changes for any reason (turn changed,
        started/stopped spectating, started browsing history). Aborts any gesture in flight.
    **/
    public function notifyConfigChanged(config:MoveInteractionConfig):Void
    {
        abortGesture();
        this.config = config;
    }

    private function onMouseDown(e:PointerEvent):Void
    {
        if (e.button != 0)
            return;

        var target:Null<HexCoords> = board.hexAtClientPoint(e.clientX, e.clientY);

        switch state
        {
            case Idle:
                tryBeginDragging(target);

            case Selected(from):
                if (target != null && target.equals(from))
                    abortGesture();
                else if (target != null && legalDestinations.exists(h -> h.equals(target)))
                    attemptMove(from, target);
                else
                {
                    abortGesture();
                    tryBeginDragging(target);
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
                updateHover(target, h -> {
                    var piece:Null<PieceData> = position.getPiece(h);
                    return piece != null && config.allowedToMove != null && piece.color == config.allowedToMove;
                }, h -> DEPARTURE_COLOR);

            case Selected(_):
                updateHover(target, isLegalDestination, destinationHoverColor);

            case Dragging(from):
                updateHover(target, isLegalDestination, destinationHoverColor);
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

    private function tryBeginDragging(target:Null<HexCoords>):Void
    {
        if (target == null)
            return;

        var piece:Null<PieceData> = position.getPiece(target);
        if (piece == null || config.allowedToMove == null || piece.color != config.allowedToMove)
            return;

        state = Dragging(target);
        legalDestinations = rules.getLegalDestinations(target, position.pieces);

        // The departure keeps the orange it got as a hover candidate; it's now owned by the
        // gesture (reset in abortGesture), not by hover tracking.
        hoveredHex = null;
        board.setHexFill(target, DEPARTURE_COLOR);
        for (destination in legalDestinations)
            markers.push(board.addMoveMarker(destination));
        board.bringPieceToFront(target);
    }

    private function attemptMove(from:HexCoords, to:HexCoords):Void
    {
        var movingPiece:PieceData = position.getPiece(from);
        var capturedPiece:Null<PieceData> = position.getPiece(to);
        abortGesture();

        if (rules.isPromotionPossible(movingPiece, to))
        {
            awaitChoice(from, to, capturedPiece, MovePrompt.promotion(board, to, movingPiece.color, kind -> {
                abortGesture();
                onMoveChosen(RawPly.construct(from, to, kind));
            }, abortGesture));
        }
        else if (rules.isChameleonPossible(movingPiece, from, capturedPiece, position.pieces))
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
        board.setHexFill(to, PROMPT_ANCHOR_COLOR);

        state = AwaitingChoice(from, to, prompt);
    }

    private function isLegalDestination(h:HexCoords):Bool
        return legalDestinations.exists(x -> x.equals(h));

    private function destinationHoverColor(h:HexCoords):String
        return h.isDark() ? DESTINATION_HOVER_DARK : DESTINATION_HOVER_LIGHT;

    private function updateHover(target:Null<HexCoords>, isReactive:HexCoords->Bool, colorOf:HexCoords->String):Void
    {
        if (HexCoords.areEqual(target, hoveredHex))
            return;

        if (hoveredHex != null)
            board.resetHexFill(hoveredHex);

        hoveredHex = (target != null && isReactive(target)) ? target : null;

        if (hoveredHex != null)
            board.setHexFill(hoveredHex, colorOf(hoveredHex));
    }

    private function abortGesture():Void
    {
        switch state
        {
            case Selected(from):
                board.resetHexFill(from);
            case Dragging(from):
                board.resetHexFill(from);
                board.resetPiecePosition(from);
            case AwaitingChoice(from, to, prompt):
                prompt.close();
                board.resetHexFill(to);
                board.setPieceVisible(to, true);
                board.resetPiecePosition(from);
            case Idle:
        }

        for (marker in markers)
            marker.element.remove();
        markers = [];
        legalDestinations = [];

        if (hoveredHex != null)
            board.resetHexFill(hoveredHex);
        hoveredHex = null;

        state = Idle;
    }
}
