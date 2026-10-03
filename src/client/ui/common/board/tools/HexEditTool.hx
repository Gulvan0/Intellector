package client.ui.common.board.tools;

import client.ui.common.board.EditIntent;
import client.ui.common.board.HexTints;
import client.ui.common.board.input.BoardGestures;
import client.ui.common.board.input.HexDrag;
import client.ui.common.board.input.HexPress;
import client.ui.common.board.input.PointerButton;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceData;
import morestd.Detachable;
import morestd.Signal;

/**
    A position editor's place or clear mode: every hex pressed - or dragged over while pressed - is
    reported as an edit (placing `piece` on it, or clearing it). The hex under the cursor is
    tinted `EditorHover`.
**/
class HexEditTool
{
    private final tints:HexTints;
    private final intents:Signal<EditIntent>;
    // null: clears hexes instead
    private final piece:Null<PieceData>;

    private var bindingHandles:Array<Detachable> = [];
    private var hoveredHex:Null<HexCoords> = null;
    // The last hex edited by the press in progress, so a drag edits each hex once.
    private var lastEditedHex:Null<HexCoords> = null;
    private var pressed:Bool = false;

    /**
        Places `piece` on the hexes the user presses.
    **/
    public static function placing(tints:HexTints, intents:Signal<EditIntent>, piece:PieceData):HexEditTool
    {
        return new HexEditTool(tints, intents, piece);
    }

    /**
        Clears the hexes the user presses.
    **/
    public static function clearing(tints:HexTints, intents:Signal<EditIntent>):HexEditTool
    {
        return new HexEditTool(tints, intents, null);
    }

    private function new(tints:HexTints, intents:Signal<EditIntent>, piece:Null<PieceData>)
    {
        this.tints = tints;
        this.intents = intents;
        this.piece = piece;
    }

    /**
        Starts editing with `button` on `gestures`; detaching the returned handle ends any press in
        progress and removes the hover tint. One binding at a time.
    **/
    public function bind(gestures:BoardGestures, button:PointerButton):Detachable
    {
        unbind();

        bindingHandles = [
            gestures.onHoverChanged(onHoverChanged),
            gestures.onPress(button, onPress),
            gestures.onDragMove(button, onDragMove),
            gestures.onRelease(button, onRelease)
        ];

        return new Detachable(unbind, false);
    }

    private function unbind():Void
    {
        for (handle in bindingHandles)
            handle.detach();
        bindingHandles = [];

        pressed = false;
        lastEditedHex = null;
        setHoveredHex(null);
    }

    private function onHoverChanged(hex:Null<HexCoords>):Void
    {
        setHoveredHex(hex);
    }

    private function onPress(press:HexPress):Void
    {
        if (press.hex == null)
            return;

        pressed = true;
        edit(press.hex);
    }

    private function onDragMove(drag:HexDrag):Void
    {
        if (pressed && drag.hex != null)
            edit(drag.hex);
    }

    private function onRelease(_:HexPress):Void
    {
        pressed = false;
        lastEditedHex = null;
    }

    private function edit(hex:HexCoords):Void
    {
        if (HexCoords.areEqual(hex, lastEditedHex))
            return;

        lastEditedHex = hex;
        intents.dispatch(piece != null ? PlacePiece(hex, piece) : ClearHex(hex));
    }

    private function setHoveredHex(hex:Null<HexCoords>):Void
    {
        if (hoveredHex != null)
            tints.remove(EditorHover, hoveredHex);

        hoveredHex = hex;

        if (hoveredHex != null)
            tints.add(EditorHover, hoveredHex);
    }
}
