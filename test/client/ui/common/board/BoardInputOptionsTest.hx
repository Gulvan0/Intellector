package client.ui.common.board;

import client.datatypes.AutoPromoteMode;
import client.ui.common.board.input.Modifiers;
import utest.Assert;
import utest.Test;

class BoardInputOptionsTest extends Test
{
    private static final NO_KEYS:Modifiers = {shift: false, ctrl: false};
    private static final SHIFT_HELD:Modifiers = {shift: true, ctrl: false};
    private static final CTRL_HELD:Modifiers = {shift: false, ctrl: true};
    private static final SHIFT_CTRL_HELD:Modifiers = {shift: true, ctrl: true};

    private var options:BoardInputOptions;

    private function setup():Void
    {
        options = new BoardInputOptions();
    }

    private function testAnnotationColorByModifiers():Void
    {
        Assert.equals(AnnotationColor.Red, options.annotationColor(NO_KEYS));
        Assert.equals(AnnotationColor.Blue, options.annotationColor(SHIFT_HELD));
        Assert.equals(AnnotationColor.Green, options.annotationColor(CTRL_HELD));
        Assert.equals(AnnotationColor.Yellow, options.annotationColor(SHIFT_CTRL_HELD));
    }

    private function testShownColorToggleOverridesModifiers():Void
    {
        options.controlsShown = true;
        options.annotationColorToggle = Green;

        Assert.equals(AnnotationColor.Green, options.annotationColor(NO_KEYS));
        Assert.equals(AnnotationColor.Green, options.annotationColor(SHIFT_CTRL_HELD));
    }

    private function testHiddenColorToggleIsIgnored():Void
    {
        options.annotationColorToggle = Green;

        Assert.equals(AnnotationColor.Blue, options.annotationColor(SHIFT_HELD));
    }

    private function testShownControlsWithoutColorToggleFallBackToModifiers():Void
    {
        options.controlsShown = true;

        Assert.equals(AnnotationColor.Yellow, options.annotationColor(SHIFT_CTRL_HELD));
    }

    private function assertAutoPromotes(mode:AutoPromoteMode, withoutShift:Bool, withShift:Bool, ?pos:haxe.PosInfos):Void
    {
        options.autoPromoteMode = mode;
        Assert.equals(withoutShift, options.autoPromotes(NO_KEYS), 'without Shift in $mode mode', pos);
        Assert.equals(withShift, options.autoPromotes(SHIFT_HELD), 'with Shift in $mode mode', pos);
    }

    private function testAutoPromotesByPreference():Void
    {
        assertAutoPromotes(NEVER, false, false);
        assertAutoPromotes(SHIFT, false, true);
        assertAutoPromotes(ALWAYS, true, true);
    }

    private function testShownToggleStandsInForAlways():Void
    {
        options.controlsShown = true;

        assertAutoPromotes(NEVER, false, false);
        assertAutoPromotes(SHIFT, false, true);
        assertAutoPromotes(ALWAYS, false, false);

        options.autoPromoteToggle = true;

        assertAutoPromotes(NEVER, true, true);
        assertAutoPromotes(SHIFT, true, true);
        assertAutoPromotes(ALWAYS, true, true);
    }

    private function testHiddenAutoPromoteToggleIsIgnored():Void
    {
        options.autoPromoteToggle = true;

        assertAutoPromotes(NEVER, false, false);
        assertAutoPromotes(SHIFT, false, true);
    }

    private function testAsksChameleonWithShift():Void
    {
        Assert.isFalse(options.asksChameleon(NO_KEYS));
        Assert.isFalse(options.asksChameleon(CTRL_HELD));
        Assert.isTrue(options.asksChameleon(SHIFT_HELD));
    }

    private function testAsksChameleonByShownToggle():Void
    {
        options.askChameleonToggle = true;
        Assert.isFalse(options.asksChameleon(NO_KEYS));

        options.controlsShown = true;
        Assert.isTrue(options.asksChameleon(NO_KEYS));
    }
}
