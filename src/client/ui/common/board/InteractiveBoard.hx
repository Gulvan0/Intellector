package client.ui.common.board;

import client.ui.common.board.annotations.AnnotationIntent;
import client.ui.common.board.annotations.BoardAnnotations;
import client.ui.common.board.input.BoardGestures;
import client.ui.common.board.move_prompt.BoardMovePrompts;
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
    A board the user interacts with, following the board preferences. The page owns the position:
    it learns of moves through `playMove` and calls `setPosition(newPosition, Move)` from the same
    handler.
**/
class InteractiveBoard extends Box
{
    /** A move the user made (or a premove that fired), for the page to apply **/
    public final playMove:Signal<RawPly> = new Signal();

    public final premoveIntents:Signal<PremoveIntent> = new Signal();
    public final editIntents:Signal<EditIntent> = new Signal();

    /** Applied to the board's own `annotations` unless the page owns them **/
    public final annotationIntents:Signal<AnnotationIntent> = new Signal();

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
        addClass(StyleClass.INTERACTIVE_BOARD);

        controlRow = new BoardControlRow(options, BoardPalette.DEFAULT);
        controlRow.onAnnotationModeChanged = onAnnotationModeChanged;
        addComponent(controlRow);

        board = new BoardSurface(position, orientation, Preferences.boardCoordinates.get());
        addComponent(board);

        gestures = new BoardGestures(board, this.element);
        tints = new HexTints(board.grid, BoardPalette.DEFAULT);

        moveTool = new PieceMoveTool(board, new BoardMovePrompts(board), tints, options, policy, playMove, premoveIntents, editIntents);
        moveToolBinding = moveTool.bind(gestures, Primary);

        annotations = new BoardAnnotations(board, board.annotationLayer, tints, Preferences.annotationHexStyle.get(), Preferences.clearAnnotationsOnPositionChange.get());
        annotationRoutingHandle = annotationIntents.subscribe(annotations.apply);
        annotationTool = new AnnotationTool(board.annotationLayer, options, annotationIntents);
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

        // starts from the preference each time a board opens; never written back
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

        // hidden controls can't be used to leave an annotation mode
        if (!shown && options.annotationColorToggle != null)
        {
            options.annotationColorToggle = null;
            controlRow.refresh();
            rebindTools();
        }
    }

    // a column left of the board in the wide layout, a row above it otherwise
    private function setControlsBeside(beside:Bool):Void
    {
        layoutName = beside ? "horizontal" : "vertical";
        controlRow.setVertical(beside);
    }

    private function onAnnotationModeChanged(_:Null<AnnotationColor>):Void
    {
        rebindTools();
    }

    /*
        The primary button annotates in the control row's selected color, or else moves or edits;
        the secondary one annotates whenever the primary doesn't.
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

    /** Releases listeners and subscriptions, aborting any gesture in flight **/
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

    /** The real position changed; with premoves, the board shows them played on top **/
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

    /** Tints `lastMove`'s departure and destination; `null` for none **/
    public function setLastMove(lastMove:Null<RawPly>):Void
    {
        var hexes:Array<HexCoords> = lastMove != null ? [lastMove.from, lastMove.to] : [];
        tints.set(LastMove, hexes);
    }

    /** What the primary button does in a position editor; aborts any gesture in flight **/
    public function setEditMode(editMode:EditMode):Void
    {
        this.editMode = editMode;
        rebindTools();
    }

    /** Aborts any gesture in flight and applies `policy` from then on **/
    public function setPolicy(policy:PieceMovePolicy):Void
    {
        moveTool.setPolicy(policy);
    }

    /** Whether the page applies `annotationIntents` itself instead of the board's `annotations` **/
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

    /** Lets `userColor` queue premoves, per the preference; returns the queue for the move policy **/
    public function enablePremoves(userColor:PieceColor, rules:MoveRules):Premoves
    {
        disablePremoves();

        var queue:Premoves = new Premoves(board, tints, rules, userColor, board.getPosition(), Preferences.premoveEnabled.get(), playMove, premoveIntents);
        premoveEnabledHandle = Preferences.premoveEnabled.onChange(queue.setEnabled);
        premoves = queue;
        return queue;
    }

    /** Drops the queued premoves and stops queuing new ones **/
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
