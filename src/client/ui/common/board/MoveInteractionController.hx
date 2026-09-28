package client.ui.common.board;

import haxe.ui.core.Screen;
import haxe.ui.events.MouseEvent;
import haxe.ui.backend.html5.svg.SVGCircleBuilder;
import intellectorboard.position.Position;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;
import intellectorboard.primitives.ply.RawPly;
import client.ui.common.overlays.move_prompt.MovePromptOverlay;

using Lambda;

private enum InteractionState
{
    Idle;
    Selected(from:HexCoords);
    Dragging(from:HexCoords);
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
    private static inline final SELECTED_COLOR:String = "#E56A00";
    private static inline final HOVER_LIGHT:String = "#83ACD4";
    private static inline final HOVER_DARK:String = "#6F8EAC";

    private final board:BoardSurface;
    private final rules:MoveRules;
    private final onMoveChosen:RawPly->Void;

    private var position:Position;
    private var config:MoveInteractionConfig;

    private var state:InteractionState = Idle;
    private var legalDestinations:Array<HexCoords> = [];
    private var markers:Array<SVGCircleBuilder> = [];
    private var hoveredHex:Null<HexCoords> = null;

    // Set while a promotion/chameleon choice is pending, so a click the overlay doesn't itself
    // consume can't also be read as a new board gesture underneath it.
    private var interactionSuspended:Bool = false;

    public function new(board:BoardSurface, position:Position, rules:MoveRules, config:MoveInteractionConfig, onMoveChosen:RawPly->Void)
    {
        this.board = board;
        this.position = position;
        this.rules = rules;
        this.config = config;
        this.onMoveChosen = onMoveChosen;

        Screen.instance.registerEvent(MouseEvent.MOUSE_DOWN, onMouseDown);
        Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
        Screen.instance.registerEvent(MouseEvent.MOUSE_UP, onMouseUp);
    }

    /**
        Releases this controller's global mouse listeners and cleans up any gesture in flight.
        Call once, when the board this controller is attached to goes away.
    **/
    public function dispose():Void
    {
        abortGesture();

        Screen.instance.unregisterEvent(MouseEvent.MOUSE_DOWN, onMouseDown);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, onMouseMove);
        Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, onMouseUp);
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

    private function onMouseDown(e:MouseEvent):Void
    {
        if (interactionSuspended)
            return;

        var target:Null<HexCoords> = board.hexAtScreenPoint(e.screenX, e.screenY);

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
        }
    }

    private function onMouseMove(e:MouseEvent):Void
    {
        if (interactionSuspended)
            return;

        var target:Null<HexCoords> = board.hexAtScreenPoint(e.screenX, e.screenY);

        switch state
        {
            case Idle:
                updateHover(target, h -> {
                    var piece:Null<PieceData> = position.getPiece(h);
                    return piece != null && config.allowedToMove != null && piece.color == config.allowedToMove;
                });

            case Selected(_):
                updateHover(target, h -> legalDestinations.exists(x -> x.equals(h)));

            case Dragging(from):
                updateHover(target, h -> legalDestinations.exists(x -> x.equals(h)));
                var boardPoint = board.screenPointToBoardPoint(e.screenX, e.screenY);
                board.movePieceTo(from, boardPoint.x, boardPoint.y);
        }
    }

    private function onMouseUp(e:MouseEvent):Void
    {
        if (interactionSuspended)
            return;

        switch state
        {
            case Dragging(from):
                var target:Null<HexCoords> = board.hexAtScreenPoint(e.screenX, e.screenY);

                if (target != null && target.equals(from))
                {
                    state = Selected(from);
                    board.resetPiecePosition(from);
                }
                else if (target != null && legalDestinations.exists(h -> h.equals(target)))
                    attemptMove(from, target);
                else
                    abortGesture();

            case Idle, Selected(_):
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

        board.setHexFill(target, SELECTED_COLOR);
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
            interactionSuspended = true;
            MovePromptOverlay.presentPromotion(movingPiece.color, kind -> {
                interactionSuspended = false;
                onMoveChosen(RawPly.construct(from, to, kind));
            });
        }
        else if (rules.isChameleonPossible(movingPiece, from, capturedPiece, position.pieces))
        {
            interactionSuspended = true;
            MovePromptOverlay.presentChameleon(chameleon -> {
                interactionSuspended = false;
                onMoveChosen(RawPly.construct(from, to, chameleon ? capturedPiece.type : null));
            });
        }
        else
            onMoveChosen(RawPly.construct(from, to));
    }

    private function updateHover(target:Null<HexCoords>, isReactive:HexCoords->Bool):Void
    {
        if (HexCoords.areEqual(target, hoveredHex))
            return;

        if (hoveredHex != null)
            board.resetHexFill(hoveredHex);

        hoveredHex = (target != null && isReactive(target)) ? target : null;

        if (hoveredHex != null)
            board.setHexFill(hoveredHex, hoveredHex.isDark() ? HOVER_DARK : HOVER_LIGHT);
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
