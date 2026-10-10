package client.ui.common.board.input;

import intellectorboard.primitives.hex.HexCoords;
import morestd.Detachable;

/** Hex-level pointer gestures and Esc for one board (`BoardGestures`), for tools to subscribe to **/
interface GestureSource
{
    /** The hex under the cursor changed (`null` off the board); never on touch **/
    public function onHoverChanged(handler:Null<HexCoords>->Void):Detachable;

    public function onPress(button:PointerButton, handler:HexPress->Void):Detachable;

    /** The pointer moved while `button`, whose press was reported, is held **/
    public function onDragMove(button:PointerButton, handler:HexDrag->Void):Detachable;

    /** `button`, whose press was reported, was released, or lost (with a `null` hex) **/
    public function onRelease(button:PointerButton, handler:HexPress->Void):Detachable;

    /** Esc was pressed and nothing else handled it **/
    public function onEscape(handler:Void->Void):Detachable;

    /**
        Reports nothing until the handle is detached; a press made meanwhile stays unreported
        through its release. One suspension at a time.
    **/
    public function suspend():Detachable;
}
