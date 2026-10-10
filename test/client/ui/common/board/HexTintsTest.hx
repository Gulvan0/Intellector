package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;
import testutils.Hexes.hex;
import testutils.board.FakeHexFills;
import utest.Assert;
import utest.Test;

class HexTintsTest extends Test
{
    private static final DARK_HEX:HexCoords = hex(0, 0);
    private static final LIGHT_HEX:HexCoords = hex(0, 2);

    private var fills:FakeHexFills;
    private var tints:HexTints;

    private function setup():Void
    {
        fills = new FakeHexFills();
        tints = new HexTints(fills, FakeHexFills.PALETTE);
    }

    private function testHexShadesFollowTheHex():Void
    {
        Assert.isTrue(DARK_HEX.isDark());
        Assert.isFalse(LIGHT_HEX.isDark());

        tints.add(LastMove, DARK_HEX);
        tints.add(LastMove, LIGHT_HEX);

        Assert.equals("lastMove/dark", fills.colorAt(DARK_HEX));
        Assert.equals("lastMove/light", fills.colorAt(LIGHT_HEX));
    }

    private function testRemovingTheOnlyTintRevertsToBaseFill():Void
    {
        tints.add(Premove, DARK_HEX);
        tints.remove(Premove, DARK_HEX);

        Assert.isNull(fills.colorAt(DARK_HEX));
    }

    private function testEarlierDeclaredTintWins():Void
    {
        tints.add(LastMove, DARK_HEX);
        tints.add(Premove, DARK_HEX);
        Assert.equals("premove", fills.entryAt(DARK_HEX));

        tints.add(DepartureHover, DARK_HEX);
        Assert.equals("departureHover", fills.entryAt(DARK_HEX));
    }

    private function testLaterAddedLowerPriorityTintStaysHidden():Void
    {
        tints.add(SelectedDeparture, DARK_HEX);
        tints.add(LastMove, DARK_HEX);

        Assert.equals("selectedDeparture", fills.entryAt(DARK_HEX));
    }

    private function testRemovingTopTintRevealsTheNext():Void
    {
        tints.add(LastMove, DARK_HEX);
        tints.add(Premove, DARK_HEX);
        tints.remove(Premove, DARK_HEX);

        Assert.equals("lastMove", fills.entryAt(DARK_HEX));
    }

    private function testRemovingUncoveredHexChangesNothing():Void
    {
        tints.add(LastMove, DARK_HEX);
        tints.remove(Premove, DARK_HEX);
        tints.remove(LastMove, LIGHT_HEX);

        Assert.equals("lastMove", fills.entryAt(DARK_HEX));
        Assert.isNull(fills.colorAt(LIGHT_HEX));
    }

    private function testSetCoversExactlyTheGivenHexes():Void
    {
        tints.set(LastMove, [hex(1, 1), hex(2, 2)]);
        tints.set(LastMove, [hex(2, 2), hex(3, 3)]);

        Assert.isNull(fills.colorAt(hex(1, 1)));
        Assert.equals("lastMove", fills.entryAt(hex(2, 2)));
        Assert.equals("lastMove", fills.entryAt(hex(3, 3)));
    }

    private function testClearLeavesOtherTints():Void
    {
        tints.set(LastMove, [hex(1, 1), hex(2, 2)]);
        tints.add(Premove, hex(2, 2));
        tints.clear(Premove);

        Assert.equals("lastMove", fills.entryAt(hex(2, 2)));

        tints.clear(LastMove);

        Assert.same([], fills.filledScalars());
    }

    private function testAnnotationFillsAreSeparateTintsPerColor():Void
    {
        tints.add(AnnotationFill(Red), DARK_HEX);
        tints.add(AnnotationFill(Blue), LIGHT_HEX);
        tints.remove(AnnotationFill(Blue), DARK_HEX);

        Assert.equals("annotationFillRed", fills.entryAt(DARK_HEX));
        Assert.equals("annotationFillBlue", fills.entryAt(LIGHT_HEX));
    }

    private function testAnnotationFillOutranksPremoveAndLastMove():Void
    {
        tints.add(LastMove, DARK_HEX);
        tints.add(Premove, DARK_HEX);
        tints.add(AnnotationFill(Green), DARK_HEX);

        Assert.equals("annotationFillGreen", fills.entryAt(DARK_HEX));
    }

    private function testNewPaletteRepaintsTintedHexes():Void
    {
        tints.add(LastMove, DARK_HEX);
        tints.setPalette(BoardPalette.DEFAULT);

        Assert.equals(BoardPalette.DEFAULT.lastMove.dark, fills.colorAt(DARK_HEX));
    }
}
