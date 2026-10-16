package client.ui.analysis.variations;

import js.html.Element;
import js.html.PointerEvent;
import js.html.WheelEvent;

/**
    Zoom gestures on `element`: a two-finger pinch, and the ctrl+wheel a trackpad pinch arrives as.
    Reports each step as a scale factor around a client point; one-finger panning stays native.
**/
class ZoomGestures
{
    private static inline final WHEEL_SENSITIVITY:Float = 0.01;
    // a mouse wheel notch arrives as one large delta; capped at about one zoom button step
    private static inline final MAX_WHEEL_FACTOR:Float = 1.25;

    private final onZoom:(factor:Float, clientX:Float, clientY:Float)->Void;
    private final pointers:Map<Int, {x:Float, y:Float}> = [];
    private var pinchDistance:Null<Float> = null;

    public function new(element:Element, onZoom:(factor:Float, clientX:Float, clientY:Float)->Void)
    {
        this.onZoom = onZoom;
        element.addEventListener("wheel", onWheel, {passive: false});
        element.addEventListener("pointerdown", onPointerDown);
        element.addEventListener("pointermove", onPointerMove);
        element.addEventListener("pointerup", onPointerEnd);
        element.addEventListener("pointercancel", onPointerEnd);
    }

    private function onWheel(event:WheelEvent):Void
    {
        if (!event.ctrlKey)
            return;

        event.preventDefault();
        var maxExponent:Float = Math.log(MAX_WHEEL_FACTOR);
        var exponent:Float = Math.max(-maxExponent, Math.min(maxExponent, -event.deltaY * WHEEL_SENSITIVITY));
        onZoom(Math.exp(exponent), event.clientX, event.clientY);
    }

    private function onPointerDown(event:PointerEvent):Void
    {
        if (event.pointerType != "touch")
            return;

        pointers.set(event.pointerId, {x: event.clientX, y: event.clientY});
        pinchDistance = currentDistance();
    }

    private function onPointerMove(event:PointerEvent):Void
    {
        if (!pointers.exists(event.pointerId))
            return;

        pointers.set(event.pointerId, {x: event.clientX, y: event.clientY});
        var distance:Null<Float> = currentDistance();
        if (distance == null || pinchDistance == null || pinchDistance <= 0)
            return;

        var points:Array<{x:Float, y:Float}> = [for (point in pointers) point];
        onZoom(distance / pinchDistance, (points[0].x + points[1].x) / 2, (points[0].y + points[1].y) / 2);
        pinchDistance = distance;
    }

    private function onPointerEnd(event:PointerEvent):Void
    {
        pointers.remove(event.pointerId);
        pinchDistance = currentDistance();
    }

    // the distance between the fingers while exactly two are down
    private function currentDistance():Null<Float>
    {
        var points:Array<{x:Float, y:Float}> = [for (point in pointers) point];
        if (points.length != 2)
            return null;
        return Math.sqrt(Math.pow(points[0].x - points[1].x, 2) + Math.pow(points[0].y - points[1].y, 2));
    }
}
