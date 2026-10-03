package client.ui.common.board.input;

import client.ui.common.board.BoardSurface;
import haxefolio.HaxeFolioApp;
import intellectorboard.primitives.hex.HexCoords;
import js.Browser;
import js.html.Element;
import js.html.Event;
import js.html.KeyboardEvent;
import js.html.Node;
import js.html.PointerEvent;
import morestd.Detachable;
import morestd.Signal;
import morestd.VoidSignal;

/**
    Turns browser pointer and key events into hex-level events for one board. Knows nothing about
    pieces, positions or rules: it reports presses, drag moves and releases per button, hover
    changes and Esc - never "clicks" or "drags", whose meaning belongs to whoever subscribes.

    Handles, once for every subscriber: hit-testing (a press or hover on something covering the
    board, like an overlay, is not on the board); releases outside the board or the window;
    the right button's context menu; touch (no hover); chorded buttons (a second button pressed
    while one is held arrives as a `pointermove`, turned into its own press and release here).

    A press off the board is reported (with `hex == null`) only if it lands on bare page
    background (`HaxeFolioApp.isPageBackground`) outside `ownArea` - an outside press; any other
    press off the board is ignored through its release. Only the primary pointer is followed.
**/
class BoardGestures
{
    private static inline final PRIMARY_BIT:Int = 1;
    private static inline final SECONDARY_BIT:Int = 2;

    private final board:BoardSurface;
    private final ownArea:Element;

    private final hoverChanged:Signal<Null<HexCoords>> = new Signal();
    private final presses:Map<PointerButton, Signal<HexPress>> = [Primary => new Signal(), Secondary => new Signal()];
    private final dragMoves:Map<PointerButton, Signal<HexDrag>> = [Primary => new Signal(), Secondary => new Signal()];
    private final releases:Map<PointerButton, Signal<HexPress>> = [Primary => new Signal(), Secondary => new Signal()];
    private final escapes:VoidSignal = new VoidSignal();

    // The buttons held, as of the last pointer event (a `PointerEvent.buttons` bitmask).
    private var heldButtons:Int = 0;
    // The held buttons whose press was reported, and so whose drag moves and release will be.
    private var reportedButtons:Int = 0;

    private var hoveredHex:Null<HexCoords> = null;
    private var reportedHoveredHex:Null<HexCoords> = null;

    private var suspended:Bool = false;

    /**
        `ownArea`: the element holding the board and its own controls, presses on which are never
        outside presses.
    **/
    public function new(board:BoardSurface, ownArea:Element)
    {
        this.board = board;
        this.ownArea = ownArea;

        // Without it, a touch drag over the board would scroll the page instead.
        board.element.style.touchAction = "none";

        /*
            Presses in the capture phase, so that a press which closes something holding a
            suspension (a prompt) is seen while still suspended, whatever order the listeners
            were registered in.
        */
        Browser.window.addEventListener("pointerdown", onPointerEvent, true);
        Browser.window.addEventListener("pointermove", onPointerEvent);
        Browser.window.addEventListener("pointerup", onPointerEvent);
        Browser.window.addEventListener("pointercancel", onPointerCancel);
        Browser.window.addEventListener("blur", onPointerCancel);
        Browser.window.addEventListener("keydown", onKeyDown);
        board.element.addEventListener("contextmenu", onContextMenu);
    }

    public function dispose():Void
    {
        Browser.window.removeEventListener("pointerdown", onPointerEvent, true);
        Browser.window.removeEventListener("pointermove", onPointerEvent);
        Browser.window.removeEventListener("pointerup", onPointerEvent);
        Browser.window.removeEventListener("pointercancel", onPointerCancel);
        Browser.window.removeEventListener("blur", onPointerCancel);
        Browser.window.removeEventListener("keydown", onKeyDown);
        board.element.removeEventListener("contextmenu", onContextMenu);
    }

    /**
        The hex under the cursor changed (`null`: off the board). Never on touch.
    **/
    public function onHoverChanged(handler:Null<HexCoords>->Void):Detachable
    {
        return hoverChanged.subscribe(handler);
    }

    public function onPress(button:PointerButton, handler:HexPress->Void):Detachable
    {
        return presses.get(button).subscribe(handler);
    }

    /**
        The pointer moved while `button`, whose press was reported, is held.
    **/
    public function onDragMove(button:PointerButton, handler:HexDrag->Void):Detachable
    {
        return dragMoves.get(button).subscribe(handler);
    }

    /**
        `button`, whose press was reported, was released - or lost, e.g. when the window lost
        focus, in which case `hex` is `null`.
    **/
    public function onRelease(button:PointerButton, handler:HexPress->Void):Detachable
    {
        return releases.get(button).subscribe(handler);
    }

    /**
        Esc was pressed and nothing else handled it: an Esc that something marked with
        `preventDefault()` (closing a prompt, an overlay, a menu, the sidebar) is ignored.
    **/
    public function onEscape(handler:Void->Void):Detachable
    {
        return escapes.subscribe(handler);
    }

    /**
        Stops reporting anything until the returned handle is detached: no hover, Esc, presses,
        drag moves or releases. A press made while suspended stays unreported through its
        release, even if the suspension ends in between. On resuming, the hover is brought up to
        date. One suspension at a time.
    **/
    public function suspend():Detachable
    {
        suspended = true;
        return new Detachable(resume, false);
    }

    private function resume():Void
    {
        suspended = false;

        if (!HexCoords.areEqual(hoveredHex, reportedHoveredHex))
            reportHover();
    }

    private function onPointerEvent(e:PointerEvent):Void
    {
        if (!e.isPrimary)
            return;

        var hex:Null<HexCoords> = board.hexAtClientPoint(e.clientX, e.clientY);

        /*
            Whatever covers the board (an overlay, a popup) takes the pointer away from it: a press
            or a hover counts as being on a hex only if the board itself is the target. A drag
            already in progress follows the pointer's coordinates wherever it goes.
        */
        var target:Node = cast e.target;
        var hexAtTarget:Null<HexCoords> = board.element.contains(target) ? hex : null;

        var modifiers:Modifiers = {shift: e.shiftKey, ctrl: e.ctrlKey || e.metaKey};

        var buttons:Int = e.buttons & (PRIMARY_BIT | SECONDARY_BIT);
        var pressed:Int = buttons & ~heldButtons;
        var released:Int = heldButtons & ~buttons;
        heldButtons = buttons;

        for (bit in [PRIMARY_BIT, SECONDARY_BIT])
            if (released & bit != 0)
                release(bit, hex, modifiers);

        if (e.pointerType != "touch")
        {
            hoveredHex = reportedButtons != 0 ? hex : hexAtTarget;
            if (!suspended && !HexCoords.areEqual(hoveredHex, reportedHoveredHex))
                reportHover();
        }

        for (bit in [PRIMARY_BIT, SECONDARY_BIT])
            if (pressed & bit != 0)
                press(bit, hexAtTarget, modifiers, e);

        if (e.type == "pointermove" && !suspended)
            for (bit in [PRIMARY_BIT, SECONDARY_BIT])
                if (reportedButtons & bit != 0)
                    dragMoves.get(buttonOf(bit)).dispatch({hex: hex, point: board.clientPointToBoardPoint(e.clientX, e.clientY), modifiers: modifiers});
    }

    // The pointer is gone without a proper release (a touch taken over by the browser, the window losing focus).
    private function onPointerCancel(_:Event):Void
    {
        for (bit in [PRIMARY_BIT, SECONDARY_BIT])
            if (heldButtons & bit != 0)
                release(bit, null, {shift: false, ctrl: false});

        heldButtons = 0;
    }

    private function press(bit:Int, hex:Null<HexCoords>, modifiers:Modifiers, e:PointerEvent):Void
    {
        if (suspended)
            return;

        var target:Node = cast e.target;
        if (hex == null && (ownArea.contains(target) || !HaxeFolioApp.isPageBackground(target)))
            return;

        // Keeps the browser from starting a text selection or a native image drag.
        if (hex != null)
            e.preventDefault();

        reportedButtons |= bit;
        presses.get(buttonOf(bit)).dispatch({hex: hex, modifiers: modifiers});
    }

    private function release(bit:Int, hex:Null<HexCoords>, modifiers:Modifiers):Void
    {
        if (reportedButtons & bit == 0)
            return;

        reportedButtons &= ~bit;

        if (!suspended)
            releases.get(buttonOf(bit)).dispatch({hex: hex, modifiers: modifiers});
    }

    private function reportHover():Void
    {
        reportedHoveredHex = hoveredHex;
        hoverChanged.dispatch(hoveredHex);
    }

    private function onKeyDown(e:KeyboardEvent):Void
    {
        if (e.key == "Escape" && !e.defaultPrevented && !suspended)
            escapes.dispatch();
    }

    private function onContextMenu(e:Event):Void
    {
        e.preventDefault();
    }

    private static function buttonOf(bit:Int):PointerButton
    {
        return bit == PRIMARY_BIT ? Primary : Secondary;
    }
}
