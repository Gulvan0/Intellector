package client.ui.common.board;

import client.ui.common.board.annotations.AnnotationIntent;
import client.ui.common.board.annotations.BoardAnnotations;
import client.ui.common.board.input.BoardGestures;
import client.ui.common.board.tools.AnnotationTool;
import client.ui.common.board.tools.HexEditTool;
import client.ui.common.board.tools.PieceMovePolicy;
import client.ui.common.board.tools.PieceMoveTool;
import client.datatypes.AutoPromoteMode;
import client.datatypes.BoardControlsVisibility;
import haxe.ui.containers.Box;
import haxefolio.PrimaryPointer;
import haxefolio.ResponsivityController;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.ply.RawPly;
import morestd.Detachable;
import morestd.Signal;

/**
    A board the user interacts with, as used by every page that has one: assembles the
    `BoardSurface`, its gestures, tints and tools, and follows the board preferences itself.

    The page owns the position: it calls `setPosition` with every new one, and learns of the
    user's moves through `playMove` (fired premoves included), applying them and calling
    `setPosition(newPosition, Move)` from the same handler. Call `dispose` when the page closes.

    On touch screens (per the "Show board controls" preference) a control row stands in for the
    right button and the modifier keys: above the board, or in a column to its left in the wide
    layout.
**/
class InteractiveBoard extends Box
{
    /**
        A move the user made (or a premove that fired), for the page to apply.
    **/
    public final playMove:Signal<RawPly> = new Signal();

    public final premoveIntents:Signal<PremoveIntent> = new Signal();
    public final editIntents:Signal<EditIntent> = new Signal();

    /**
        What the user asked of the annotations. Applied to the board's own annotations unless the
        page takes them over (`setAnnotationsOwnedByPage`).
    **/
    public final annotationIntents:Signal<AnnotationIntent> = new Signal();

    /**
        The board's own annotations, which `annotationIntents` are applied to by default.
    **/
    public final annotations:BoardAnnotations;

    private final board:BoardSurface;
    private final gestures:BoardGestures;
    private final tints:HexTints;
    private final options:BoardInputOptions = new BoardInputOptions();
    private final moveTool:PieceMoveTool;
    private var moveToolBinding:Detachable;
    private final annotationTool:AnnotationTool;
    private var annotationToolBinding:Detachable;
    private var annotationRoutingHandle:Null<Detachable>;

    private var editMode:EditMode = Moving;
    private var editToolBinding:Null<Detachable> = null;

    private final controlRow:BoardControlRow;
    private var controlsVisibility:BoardControlsVisibility;
    private var pointerIsCoarse:Bool = false;

    private var premoves:Null<Premoves> = null;
    private var premoveEnabledHandle:Null<Detachable> = null;

    private var preferenceHandles:Array<Detachable> = [];

    public function new(position:Position, orientation:PieceColor, policy:PieceMovePolicy)
    {
        super();
        this.percentWidth = 100;

        controlRow = new BoardControlRow(options, BoardPalette.DEFAULT);
        controlRow.onAnnotationModeChanged = onAnnotationModeChanged;
        addComponent(controlRow);

        board = new BoardSurface(position, orientation, Preferences.boardCoordinates.get());
        addComponent(board);

        gestures = new BoardGestures(board, this.element);
        tints = new HexTints(board.grid, BoardPalette.DEFAULT);

        moveTool = new PieceMoveTool(board, tints, options, policy, playMove, premoveIntents, editIntents);
        moveToolBinding = moveTool.bind(gestures, Primary);

        annotations = new BoardAnnotations(board, tints, Preferences.annotationHexStyle.get(), Preferences.clearAnnotationsOnPositionChange.get());
        annotationRoutingHandle = annotationIntents.subscribe(annotations.apply);
        annotationTool = new AnnotationTool(board, options, annotationIntents);
        annotationTool.clearsOnPrimaryPress = Preferences.clearAnnotationsOnClick.get();
        annotationToolBinding = annotationTool.bind(gestures, Secondary);

        preferenceHandles.push(Preferences.boardCoordinates.onChange(board.setCoordinatesMode));
        preferenceHandles.push(Preferences.annotationHexStyle.onChange(annotations.setHexStyle));
        preferenceHandles.push(Preferences.clearAnnotationsOnPositionChange.onChange(annotations.setClearsOnPositionChange));
        preferenceHandles.push(Preferences.clearAnnotationsOnClick.onChange(clears -> {
            annotationTool.clearsOnPrimaryPress = clears;
        }));

        options.autoPromoteMode = Preferences.autoPromote.get();
        preferenceHandles.push(Preferences.autoPromote.onChange(mode -> {
            options.autoPromoteMode = mode;
        }));

        // Starts from the preference each time a board opens; never written back.
        options.autoPromoteToggle = options.autoPromoteMode == ALWAYS;
        controlRow.refresh();

        controlsVisibility = Preferences.boardControls.get();
        preferenceHandles.push(Preferences.boardControls.onChange(visibility -> {
            controlsVisibility = visibility;
            updateControlsVisibility();
        }));
        preferenceHandles.push(PrimaryPointer.bind(coarse -> {
            pointerIsCoarse = coarse;
            updateControlsVisibility();
        }));
        preferenceHandles.push(ResponsivityController.bind({expanded: true, collapsed: false}, setControlsBeside));
    }

    private function updateControlsVisibility():Void
    {
        var shown:Bool = switch controlsVisibility {
            case ALWAYS: true;
            case NEVER: false;
            default: pointerIsCoarse;
        }

        controlRow.hidden = !shown;
        options.controlsShown = shown;

        // Hidden controls can't be used to leave an annotation mode.
        if (!shown && options.annotationColorToggle != null)
        {
            options.annotationColorToggle = null;
            controlRow.refresh();
            rebindTools();
        }
    }

    // A column to the left of the board in the wide layout, a row above it otherwise.
    private function setControlsBeside(beside:Bool):Void
    {
        layoutName = beside ? "horizontal" : "vertical";
        customStyle.horizontalSpacing = 8;
        customStyle.verticalSpacing = 8;
        invalidateComponentStyle();
        controlRow.setVertical(beside);
    }

    private function onAnnotationModeChanged(_:Null<AnnotationColor>):Void
    {
        rebindTools();
    }

    /*
        What the primary button does: annotating in the control row's annotation color, if one is
        selected; otherwise moving pieces, or the edit mode's placing/clearing. The secondary
        button annotates whenever the primary one doesn't.
    */
    private function rebindTools():Void
    {
        moveToolBinding.detach();
        annotationToolBinding.detach();
        if (editToolBinding != null)
            editToolBinding.detach();
        editToolBinding = null;

        if (options.controlsShown && options.annotationColorToggle != null)
        {
            annotationToolBinding = annotationTool.bind(gestures, Primary);
            return;
        }

        annotationToolBinding = annotationTool.bind(gestures, Secondary);

        switch editMode
        {
            case Moving:
                moveToolBinding = moveTool.bind(gestures, Primary);
            case Placing(piece):
                editToolBinding = HexEditTool.placing(tints, editIntents, piece).bind(gestures, Primary);
            case Clearing:
                editToolBinding = HexEditTool.clearing(tints, editIntents).bind(gestures, Primary);
        }
    }

    /**
        Releases the board's listeners and preference subscriptions; any gesture in flight is
        aborted.
    **/
    public function dispose():Void
    {
        moveToolBinding.detach();
        moveTool.dispose();
        if (editToolBinding != null)
            editToolBinding.detach();
        annotationToolBinding.detach();
        annotationTool.dispose();
        setAnnotationsOwnedByPage(true);
        annotations.dispose();
        gestures.dispose();

        disablePremoves();

        for (handle in preferenceHandles)
            handle.detach();
        preferenceHandles = [];
    }

    /**
        The real position changed: `Move` for a move played by either side, `Replacement` for
        anything else (history navigation, rollback, reset). With premoves enabled, the board shows
        it with the queued premoves played on top.
    **/
    public function setPosition(position:Position, cause:PositionChangeCause):Void
    {
        if (premoves != null)
            premoves.setRealPosition(position, cause);
        else
            board.setPosition(position, cause);
    }

    public function setOrientation(orientation:PieceColor):Void
    {
        board.setOrientation(orientation);
    }

    public function getOrientation():PieceColor
    {
        return board.getOrientation();
    }

    /**
        Tints the departure and destination of `lastMove`, the move that led to the shown position
        (`null`: none).
    **/
    public function setLastMove(lastMove:Null<RawPly>):Void
    {
        var hexes:Array<HexCoords> = lastMove != null ? [lastMove.from, lastMove.to] : [];
        tints.set(LastMove, hexes);
    }

    /**
        What the primary button does in a position editor (`Moving` everywhere else). Aborts any
        gesture in flight.
    **/
    public function setEditMode(editMode:EditMode):Void
    {
        this.editMode = editMode;
        rebindTools();
    }

    /**
        Aborts any gesture in flight and applies `policy` from then on.
    **/
    public function setPolicy(policy:PieceMovePolicy):Void
    {
        moveTool.setPolicy(policy);
    }

    /**
        Whether the page applies `annotationIntents` itself (e.g. keeping annotations per position)
        instead of the board's own `annotations`.
    **/
    public function setAnnotationsOwnedByPage(owned:Bool):Void
    {
        if (owned && annotationRoutingHandle != null)
        {
            annotationRoutingHandle.detach();
            annotationRoutingHandle = null;
        }
        else if (!owned && annotationRoutingHandle == null)
            annotationRoutingHandle = annotationIntents.subscribe(annotations.apply);
    }

    /**
        Lets `userColor` queue premoves (live games), following the premove preference. Returns
        the queue, for the page's move policy to consult (see `LiveGameMovePolicy`).
    **/
    public function enablePremoves(userColor:PieceColor, rules:MoveRules):Premoves
    {
        disablePremoves();

        var queue:Premoves = new Premoves(board, tints, rules, userColor, board.getPosition(), Preferences.premoveEnabled.get(), playMove, premoveIntents);
        premoveEnabledHandle = Preferences.premoveEnabled.onChange(queue.setEnabled);
        premoves = queue;
        return queue;
    }

    /**
        Drops the queued premoves and stops queuing new ones (e.g. at the end of a game).
    **/
    public function disablePremoves():Void
    {
        if (premoves == null)
            return;

        premoveEnabledHandle.detach();
        premoveEnabledHandle = null;
        premoves.dispose();
        premoves = null;
    }
}
