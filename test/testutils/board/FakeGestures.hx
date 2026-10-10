package testutils.board;

import client.ui.common.board.BoardPoint;
import client.ui.common.board.input.GestureSource;
import client.ui.common.board.input.HexDrag;
import client.ui.common.board.input.HexPress;
import client.ui.common.board.input.Modifiers;
import client.ui.common.board.input.PointerButton;
import intellectorboard.primitives.hex.HexCoords;
import morestd.Detachable;
import morestd.Signal;
import morestd.VoidSignal;

/** Gestures played by the test; nothing is reported while suspended **/
class FakeGestures implements GestureSource
{
    public static final NO_KEYS:Modifiers = {shift: false, ctrl: false};

    public var suspended(default, null):Bool = false;

    private final hoverChanged:Signal<Null<HexCoords>> = new Signal();
    private final presses:Map<PointerButton, Signal<HexPress>> = [Primary => new Signal(), Secondary => new Signal()];
    private final dragMoves:Map<PointerButton, Signal<HexDrag>> = [Primary => new Signal(), Secondary => new Signal()];
    private final releases:Map<PointerButton, Signal<HexPress>> = [Primary => new Signal(), Secondary => new Signal()];
    private final escapes:VoidSignal = new VoidSignal();

    public function new() {}

    public function onHoverChanged(handler:Null<HexCoords>->Void):Detachable
    {
        return hoverChanged.subscribe(handler);
    }

    public function onPress(button:PointerButton, handler:HexPress->Void):Detachable
    {
        return presses.get(button).subscribe(handler);
    }

    public function onDragMove(button:PointerButton, handler:HexDrag->Void):Detachable
    {
        return dragMoves.get(button).subscribe(handler);
    }

    public function onRelease(button:PointerButton, handler:HexPress->Void):Detachable
    {
        return releases.get(button).subscribe(handler);
    }

    public function onEscape(handler:Void->Void):Detachable
    {
        return escapes.subscribe(handler);
    }

    public function suspend():Detachable
    {
        suspended = true;
        return new Detachable(() -> {
            suspended = false;
        }, false);
    }

    public function hover(hex:Null<HexCoords>):Void
    {
        if (!suspended)
            hoverChanged.dispatch(hex);
    }

    public function press(button:PointerButton, hex:Null<HexCoords>, ?modifiers:Modifiers):Void
    {
        if (!suspended)
            presses.get(button).dispatch({hex: hex, modifiers: modifiers ?? NO_KEYS});
    }

    /** A drag move over `hex`, at `point` (an arbitrary one if omitted) **/
    public function drag(button:PointerButton, hex:Null<HexCoords>, ?point:BoardPoint):Void
    {
        if (!suspended)
            dragMoves.get(button).dispatch({hex: hex, point: point ?? {x: 1, y: 2}, modifiers: NO_KEYS});
    }

    public function release(button:PointerButton, hex:Null<HexCoords>, ?modifiers:Modifiers):Void
    {
        if (!suspended)
            releases.get(button).dispatch({hex: hex, modifiers: modifiers ?? NO_KEYS});
    }

    /** A press and a release on the same hex **/
    public function click(button:PointerButton, hex:Null<HexCoords>, ?modifiers:Modifiers):Void
    {
        press(button, hex, modifiers);
        release(button, hex, modifiers);
    }

    public function escape():Void
    {
        if (!suspended)
            escapes.dispatch();
    }
}
