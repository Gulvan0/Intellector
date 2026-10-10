package client.ui.common.board.tools;

import client.ui.common.board.EditIntent;
import client.ui.common.board.HexTints;
import intellectorboard.primitives.piece.PieceData;
import morestd.Detachable;
import morestd.Signal;
import testutils.Hexes.hex;
import testutils.board.FakeGestures;
import testutils.board.FakeHexFills;
import utest.Assert;
import utest.Test;

class HexEditToolTest extends Test
{
    private static final PIECE:PieceData = new PieceData(Liberator, Black);

    private var gestures:FakeGestures;
    private var fills:FakeHexFills;
    private var tints:HexTints;
    private var intentSignal:Signal<EditIntent>;
    private var intents:Array<EditIntent>;

    private function setup():Void
    {
        gestures = new FakeGestures();
        fills = new FakeHexFills();
        tints = new HexTints(fills, FakeHexFills.PALETTE);
        intents = [];
        intentSignal = new Signal();
        intentSignal.subscribe(intents.push);
    }

    private function bindPlacing():Detachable
    {
        return HexEditTool.placing(tints, intentSignal, PIECE).bind(gestures, Primary);
    }

    private function testPressPlacesPiece():Void
    {
        bindPlacing();
        gestures.click(Primary, hex(4, 3));

        Assert.same([EditIntent.PlacePiece(hex(4, 3), PIECE)], intents);
    }

    private function testClearingToolClearsHexes():Void
    {
        HexEditTool.clearing(tints, intentSignal).bind(gestures, Primary);
        gestures.click(Primary, hex(4, 3));

        Assert.same([EditIntent.ClearHex(hex(4, 3))], intents);
    }

    private function testDragEditsEveryHexEnteredOnce():Void
    {
        bindPlacing();
        gestures.press(Primary, hex(4, 3));
        gestures.drag(Primary, hex(4, 3));
        gestures.drag(Primary, hex(4, 2));
        gestures.drag(Primary, hex(4, 2));
        gestures.drag(Primary, null);
        gestures.drag(Primary, hex(4, 1));
        gestures.release(Primary, hex(4, 1));

        Assert.same([
            EditIntent.PlacePiece(hex(4, 3), PIECE),
            EditIntent.PlacePiece(hex(4, 2), PIECE),
            EditIntent.PlacePiece(hex(4, 1), PIECE)
        ], intents);
    }

    private function testReenteringAHexAfterAnotherEditsItAgain():Void
    {
        bindPlacing();
        gestures.press(Primary, hex(4, 3));
        gestures.drag(Primary, hex(4, 2));
        gestures.drag(Primary, hex(4, 3));

        Assert.equals(3, intents.length);
    }

    private function testNewPressOnSameHexEditsAgain():Void
    {
        bindPlacing();
        gestures.click(Primary, hex(4, 3));
        gestures.click(Primary, hex(4, 3));

        Assert.equals(2, intents.length);
    }

    private function testDragWithoutPressEditsNothing():Void
    {
        bindPlacing();
        gestures.press(Primary, null);
        gestures.drag(Primary, hex(4, 2));
        gestures.click(Primary, hex(4, 3));
        gestures.drag(Primary, hex(4, 2));

        Assert.same([EditIntent.PlacePiece(hex(4, 3), PIECE)], intents);
    }

    private function testHoveredHexIsTinted():Void
    {
        bindPlacing();
        gestures.hover(hex(4, 3));
        Assert.equals("editorHover", fills.entryAt(hex(4, 3)));

        gestures.hover(hex(4, 2));
        Assert.isNull(fills.colorAt(hex(4, 3)));
        Assert.equals("editorHover", fills.entryAt(hex(4, 2)));

        gestures.hover(null);
        Assert.same([], fills.filledScalars());
    }

    private function testUnbindingDropsHoverAndPress():Void
    {
        var binding:Detachable = bindPlacing();
        gestures.hover(hex(4, 3));
        gestures.press(Primary, hex(4, 3));
        binding.detach();

        Assert.same([], fills.filledScalars());

        gestures.drag(Primary, hex(4, 2));

        Assert.equals(1, intents.length);
    }
}
