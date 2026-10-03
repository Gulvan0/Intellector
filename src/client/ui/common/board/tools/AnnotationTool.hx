package client.ui.common.board.tools;

import client.ui.common.board.AnnotationColor;
import client.ui.common.board.BoardInputOptions;
import client.ui.common.board.BoardSurface;
import client.ui.common.board.annotations.ArrowAnnotation;
import client.ui.common.board.annotations.AnnotationIntent;
import client.ui.common.board.input.BoardGestures;
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
    Drawing annotations with the button it's bound to: press and release on one hex annotates the
    hex, on two hexes draws an arrow between them (previewed while dragging). The color is taken
    once, at the press. Reports `AnnotationIntent`s; applies nothing itself.

    When bound to a button other than `Primary`, a `Primary` press anywhere on the board or on the
    page background also reports `ClearAnnotations`, if `clearsOnPrimaryPress`.
**/
class AnnotationTool
{
    /**
        Whether a primary press clears the annotations (see the class description).
    **/
    public var clearsOnPrimaryPress:Bool = true;

    private final board:BoardSurface;
    private final options:BoardInputOptions;
    private final intents:Signal<AnnotationIntent>;

    private var bindingHandles:Array<Detachable> = [];
    private var started:Null<StartedAnnotation> = null;
    private var previewArrow:Null<ArrowAnnotation> = null;

    public function new(board:BoardSurface, options:BoardInputOptions, intents:Signal<AnnotationIntent>)
    {
        this.board = board;
        this.options = options;
        this.intents = intents;
    }

    /**
        Starts drawing with `drawButton` on `gestures`. Detaching the returned handle drops an
        annotation being drawn. One binding at a time.
    **/
    public function bind(gestures:BoardGestures, drawButton:PointerButton):Detachable
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
        // An outside press never starts (or clears) anything here.
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
        board.annotationLayer.setPreviewArrow(arrow);
    }
}
