package client.ui.common.board.tools;

import client.ui.common.board.AnnotationColor;
import client.ui.common.board.BoardInputOptions;
import client.ui.common.board.annotations.AnnotationCanvas;
import client.ui.common.board.annotations.ArrowAnnotation;
import client.ui.common.board.annotations.AnnotationIntent;
import client.ui.common.board.input.GestureSource;
import client.ui.common.board.input.HexDrag;
import client.ui.common.board.input.HexPress;
import client.ui.common.board.input.PointerButton;
import intellectorboard.primitives.hex.HexCoords;
import morestd.Detachable;
import morestd.Signal;

private typedef StartedAnnotation =
{
    from:HexCoords,
    color:AnnotationColor
}

/**
    Draws annotations with its button, only reporting `AnnotationIntent`s: press and release on one
    hex annotates it, on two draws an arrow (previewed while dragging), in the color taken at the
    press.
**/
class AnnotationTool
{
    /** Whether a `Primary` press anywhere clears the annotations, when bound to another button **/
    public var clearsOnPrimaryPress:Bool = true;

    private final canvas:AnnotationCanvas;
    private final options:BoardInputOptions;
    private final intents:Signal<AnnotationIntent>;

    private var bindingHandles:Array<Detachable> = [];
    private var started:Null<StartedAnnotation> = null;
    private var previewArrow:Null<ArrowAnnotation> = null;

    public function new(canvas:AnnotationCanvas, options:BoardInputOptions, intents:Signal<AnnotationIntent>)
    {
        this.canvas = canvas;
        this.options = options;
        this.intents = intents;
    }

    /**
        Starts drawing with `drawButton`; detaching the handle drops the annotation in progress. One
        binding at a time.
    **/
    public function bind(gestures:GestureSource, drawButton:PointerButton):Detachable
    {
        unbind();

        bindingHandles = [
            gestures.onPress(drawButton, onDrawPress),
            gestures.onDragMove(drawButton, onDrawDrag),
            gestures.onRelease(drawButton, onDrawRelease)
        ];
        if (drawButton != Primary)
            bindingHandles.push(gestures.onPress(Primary, onPrimaryPress));

        return new Detachable(unbind, false);
    }

    public function dispose():Void
    {
        unbind();
    }

    private function unbind():Void
    {
        for (handle in bindingHandles)
            handle.detach();
        bindingHandles = [];

        started = null;
        setPreviewArrow(null);
    }

    private function onDrawPress(press:HexPress):Void
    {
        // an outside press starts nothing
        if (press.hex == null)
            return;

        started = {from: press.hex, color: options.annotationColor(press.modifiers)};
    }

    private function onDrawDrag(drag:HexDrag):Void
    {
        if (started == null)
            return;

        if (drag.hex == null || drag.hex.equals(started.from))
            setPreviewArrow(null);
        else
            setPreviewArrow({from: started.from, to: drag.hex, color: started.color});
    }

    private function onDrawRelease(release:HexPress):Void
    {
        if (started == null)
            return;

        var annotation:StartedAnnotation = started;
        started = null;
        setPreviewArrow(null);

        if (release.hex == null)
            return;

        if (release.hex.equals(annotation.from))
            intents.dispatch(AnnotateHex(annotation.from, annotation.color));
        else
            intents.dispatch(AnnotateArrow(annotation.from, release.hex, annotation.color));
    }

    private function onPrimaryPress(_:HexPress):Void
    {
        if (clearsOnPrimaryPress)
            intents.dispatch(ClearAnnotations);
    }

    private function setPreviewArrow(arrow:Null<ArrowAnnotation>):Void
    {
        if (arrow == null && previewArrow == null)
            return;
        if (arrow != null && previewArrow != null && arrow.to.equals(previewArrow.to) && arrow.from.equals(previewArrow.from))
            return;

        previewArrow = arrow;
        canvas.setPreviewArrow(arrow);
    }
}
