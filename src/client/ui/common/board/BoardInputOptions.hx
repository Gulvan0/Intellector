package client.ui.common.board;

import client.datatypes.AutoPromoteMode;
import client.ui.common.board.input.Modifiers;

/**
    What the user means beyond the gesture itself, from the modifier keys (desktop) or the control
    row's toggles (touch). Tools pass the modifiers held at the moment that counts.
**/
class BoardInputOptions
{
    /** The auto-promote preference: `never` ignores Shift, `shift` promotes with it, `always` without **/
    public var autoPromoteMode:AutoPromoteMode = SHIFT;

    /** Whether the control row is shown; its toggles only count while it is **/
    public var controlsShown:Bool = false;

    /** The control row's "Auto-promote to Dominator" toggle; stands in for `always` while shown **/
    public var autoPromoteToggle:Bool = false;

    /** The control row's "Ask about chameleon" toggle **/
    public var askChameleonToggle:Bool = false;

    /** The color the primary button annotates in, or `null` for the normal mode (moving pieces) **/
    public var annotationColorToggle:Null<AnnotationColor> = null;

    public function new() {}

    /**
        The color of an annotation started with `modifiers`: the control row's if selected, else
        none - red, Shift - blue, Ctrl - green, Shift+Ctrl - yellow.
    **/
    public function annotationColor(modifiers:Modifiers):AnnotationColor
    {
        if (controlsShown && annotationColorToggle != null)
            return annotationColorToggle;

        return switch [modifiers.shift, modifiers.ctrl] {
            case [false, false]: Red;
            case [true, false]: Blue;
            case [false, true]: Green;
            case [true, true]: Yellow;
        }
    }

    /** Whether a promotion completed with `modifiers` held becomes a Dominator without asking **/
    public function autoPromotes(modifiers:Modifiers):Bool
    {
        var byShift:Bool = autoPromoteMode == SHIFT && modifiers.shift;
        if (controlsShown)
            return autoPromoteToggle || byShift;
        return autoPromoteMode == ALWAYS || byShift;
    }

    /** Whether a possible chameleon premove completed with `modifiers` asks which kind to morph into **/
    public function asksChameleon(modifiers:Modifiers):Bool
    {
        return (controlsShown && askChameleonToggle) || modifiers.shift;
    }
}
