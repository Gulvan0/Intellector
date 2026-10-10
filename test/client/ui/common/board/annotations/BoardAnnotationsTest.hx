package client.ui.common.board.annotations;

import client.ui.common.board.HexTints;
import intellectorboard.position.Position;
import testutils.Hexes.hex;
import testutils.Positions;
import testutils.board.FakeAnnotationCanvas;
import testutils.board.FakeBoardView;
import testutils.board.FakeHexFills;
import utest.Assert;
import utest.Test;

class BoardAnnotationsTest extends Test
{
    private var board:FakeBoardView;
    private var canvas:FakeAnnotationCanvas;
    private var fills:FakeHexFills;
    private var annotations:BoardAnnotations;

    private function setup():Void
    {
        board = new FakeBoardView(Position.defaultStarting());
        canvas = new FakeAnnotationCanvas();
        fills = new FakeHexFills();
        annotations = new BoardAnnotations(board, canvas, new HexTints(fills, FakeHexFills.PALETTE), CIRCLE, false);
    }

    private function ringScalars():Array<Int>
    {
        return Positions.scalars([for (ring in canvas.rings) ring.hex]);
    }

    private function testHexAnnotationIsDrawnAsRing():Void
    {
        annotations.apply(AnnotateHex(hex(4, 3), Green));

        Assert.equals(1, canvas.rings.length);
        Assert.isTrue(canvas.rings[0].hex.equals(hex(4, 3)));
        Assert.equals(AnnotationColor.Green, canvas.rings[0].color);
        Assert.same([], fills.filledScalars());
    }

    private function testAnnotatingAnnotatedHexInAnyColorRemovesIt():Void
    {
        annotations.toggleHex(hex(4, 3), Green);
        annotations.toggleHex(hex(2, 2), Red);
        annotations.toggleHex(hex(4, 3), Blue);

        Assert.same(Positions.scalars([hex(2, 2)]), ringScalars());
    }

    private function testArrowsAreKeptPerOrderedPair():Void
    {
        annotations.apply(AnnotateArrow(hex(4, 5), hex(4, 3), Red));
        annotations.apply(AnnotateArrow(hex(4, 3), hex(4, 5), Blue));

        Assert.equals(2, canvas.arrows.length);

        annotations.apply(AnnotateArrow(hex(4, 5), hex(4, 3), Yellow));

        Assert.equals(1, canvas.arrows.length);
        Assert.isTrue(canvas.arrows[0].from.equals(hex(4, 3)));
        Assert.equals(AnnotationColor.Blue, canvas.arrows[0].color);
    }

    private function testClearIntentRemovesEverything():Void
    {
        annotations.apply(AnnotateHex(hex(4, 3), Green));
        annotations.apply(AnnotateArrow(hex(4, 5), hex(4, 3), Red));
        annotations.apply(ClearAnnotations);

        Assert.same([], canvas.rings);
        Assert.same([], canvas.arrows);
    }

    private function testTintStyleFillsHexesInsteadOfRings():Void
    {
        annotations.setHexStyle(TINT);
        annotations.toggleHex(hex(4, 3), Green);
        annotations.toggleArrow(hex(4, 5), hex(4, 3), Red);

        Assert.same([], canvas.rings);
        Assert.equals(1, canvas.arrows.length);
        Assert.equals("annotationFillGreen", fills.entryAt(hex(4, 3)));
    }

    private function testSwitchingStyleRedrawsExistingAnnotations():Void
    {
        annotations.toggleHex(hex(4, 3), Yellow);
        annotations.setHexStyle(TINT);

        Assert.same([], canvas.rings);
        Assert.equals("annotationFillYellow", fills.entryAt(hex(4, 3)));

        annotations.setHexStyle(CIRCLE);

        Assert.same(Positions.scalars([hex(4, 3)]), ringScalars());
        Assert.same([], fills.filledScalars());
    }

    private function testPositionChangeKeepsAnnotationsUnlessSetToClear():Void
    {
        annotations.toggleHex(hex(4, 3), Green);
        board.setPosition(Position.defaultStarting(), Move);

        Assert.equals(1, canvas.rings.length);

        annotations.setClearsOnPositionChange(true);
        board.setPosition(Position.defaultStarting(), Replacement);

        Assert.same([], canvas.rings);
    }

    private function testDisposeClearsAndStopsFollowingPosition():Void
    {
        annotations.setHexStyle(TINT);
        annotations.setClearsOnPositionChange(true);
        annotations.toggleHex(hex(4, 3), Green);
        annotations.dispose();

        Assert.same([], fills.filledScalars());

        annotations.toggleHex(hex(2, 2), Red);
        board.setPosition(Position.defaultStarting(), Move);

        Assert.equals("annotationFillRed", fills.entryAt(hex(2, 2)));
    }
}
