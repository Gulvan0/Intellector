package client.ui.common.board.tools;

import client.ui.common.board.AnnotationColor;
import client.ui.common.board.BoardInputOptions;
import client.ui.common.board.annotations.AnnotationIntent;
import morestd.Detachable;
import morestd.Signal;
import testutils.Hexes.hex;
import testutils.board.FakeAnnotationCanvas;
import testutils.board.FakeGestures;
import utest.Assert;
import utest.Test;

class AnnotationToolTest extends Test
{
    private var gestures:FakeGestures;
    private var canvas:FakeAnnotationCanvas;
    private var options:BoardInputOptions;
    private var intents:Array<AnnotationIntent>;
    private var tool:AnnotationTool;
    private var binding:Detachable;

    private function setup():Void
    {
        gestures = new FakeGestures();
        canvas = new FakeAnnotationCanvas();
        options = new BoardInputOptions();
        intents = [];

        var intentSignal:Signal<AnnotationIntent> = new Signal();
        intentSignal.subscribe(intents.push);

        tool = new AnnotationTool(canvas, options, intentSignal);
        binding = tool.bind(gestures, Secondary);
    }

    private function testClickAnnotatesHex():Void
    {
        gestures.click(Secondary, hex(4, 3));

        Assert.same([AnnotationIntent.AnnotateHex(hex(4, 3), Red)], intents);
    }

    private function testColorIsTakenAtPress():Void
    {
        gestures.press(Secondary, hex(4, 3), {shift: true, ctrl: false});
        gestures.release(Secondary, hex(4, 3), {shift: false, ctrl: true});

        Assert.same([AnnotationIntent.AnnotateHex(hex(4, 3), Blue)], intents);
    }

    private function testShownColorToggleOverridesModifiers():Void
    {
        options.controlsShown = true;
        options.annotationColorToggle = Yellow;

        gestures.click(Secondary, hex(4, 3), {shift: true, ctrl: false});

        Assert.same([AnnotationIntent.AnnotateHex(hex(4, 3), Yellow)], intents);
    }

    private function testReleaseOnAnotherHexDrawsArrow():Void
    {
        gestures.press(Secondary, hex(4, 5));
        gestures.release(Secondary, hex(4, 3));

        Assert.same([AnnotationIntent.AnnotateArrow(hex(4, 5), hex(4, 3), Red)], intents);
    }

    private function testDragPreviewsArrow():Void
    {
        gestures.press(Secondary, hex(4, 5), {shift: false, ctrl: true});
        gestures.drag(Secondary, hex(4, 4));

        Assert.notNull(canvas.previewArrow);
        Assert.isTrue(canvas.previewArrow.from.equals(hex(4, 5)));
        Assert.isTrue(canvas.previewArrow.to.equals(hex(4, 4)));
        Assert.equals(AnnotationColor.Green, canvas.previewArrow.color);

        gestures.drag(Secondary, hex(4, 5));
        Assert.isNull(canvas.previewArrow);

        gestures.drag(Secondary, null);
        Assert.isNull(canvas.previewArrow);

        gestures.drag(Secondary, hex(4, 3));
        gestures.release(Secondary, hex(4, 3));

        Assert.isNull(canvas.previewArrow);
        Assert.same([AnnotationIntent.AnnotateArrow(hex(4, 5), hex(4, 3), Green)], intents);
    }

    private function testDraggingWithinSameHexDoesNotRedrawPreview():Void
    {
        gestures.press(Secondary, hex(4, 5));
        gestures.drag(Secondary, hex(4, 4));
        gestures.drag(Secondary, hex(4, 4));

        Assert.equals(1, canvas.previewUpdates);
    }

    private function testReleaseOffBoardDrawsNothing():Void
    {
        gestures.press(Secondary, hex(4, 5));
        gestures.drag(Secondary, hex(4, 4));
        gestures.release(Secondary, null);

        Assert.same([], intents);
        Assert.isNull(canvas.previewArrow);
    }

    private function testPressOffBoardStartsNothing():Void
    {
        gestures.press(Secondary, null);
        gestures.drag(Secondary, hex(4, 4));
        gestures.release(Secondary, hex(4, 4));

        Assert.same([], intents);
        Assert.isNull(canvas.previewArrow);
    }

    private function testPrimaryPressClearsWhenBoundElsewhere():Void
    {
        gestures.press(Primary, hex(4, 4));
        Assert.same([AnnotationIntent.ClearAnnotations], intents);

        tool.clearsOnPrimaryPress = false;
        gestures.press(Primary, hex(4, 4));
        Assert.equals(1, intents.length);
    }

    private function testBoundToPrimaryItDrawsInsteadOfClearing():Void
    {
        binding.detach();
        tool.bind(gestures, Primary);

        gestures.click(Primary, hex(4, 4));

        Assert.same([AnnotationIntent.AnnotateHex(hex(4, 4), Red)], intents);
    }

    private function testUnbindingDropsAnnotationInProgress():Void
    {
        gestures.press(Secondary, hex(4, 5));
        gestures.drag(Secondary, hex(4, 4));
        binding.detach();

        Assert.isNull(canvas.previewArrow);

        gestures.release(Secondary, hex(4, 4));
        gestures.press(Primary, hex(4, 4));

        Assert.same([], intents);
    }

    private function testRebindingReplacesPreviousBinding():Void
    {
        tool.bind(gestures, Secondary);
        gestures.click(Secondary, hex(4, 4));

        Assert.equals(1, intents.length);
    }
}
