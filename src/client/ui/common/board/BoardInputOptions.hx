package client.ui.common.board;

import client.datatypes.AutoPromoteMode;
import client.ui.common.board.input.Modifiers;

/**
    What the user means by their next gesture beyond the gesture itself, from two sources tools
    can't tell apart: the modifier keys held (desktop) and the board control row's toggles
    (touch screens). Tools ask it, passing the modifiers held at the moment that counts.
**/
class BoardInputOptions
{
    /**
        The auto-promote preference: `never` ignores Shift, `shift` promotes with it, `always`
        promotes without it.
    **/
    public var autoPromoteMode:AutoPromoteMode = SHIFT;

    /**
        Whether the control row is shown. Its toggles only count while it is.
    **/
    public var controlsShown:Bool = false;

    /**
        The control row's "Auto-promote to Dominator" toggle. While the row is shown, it stands in
        for the `always` preference value.
    **/
    public var autoPromoteToggle:Bool = false;

    /**
        The control row's "Ask about chameleon" toggle.
    **/
    public var askChameleonToggle:Bool = false;

    /**
        The control row's annotation mode: the color the primary button annotates in, or `null`
        for the normal mode (the primary button moves pieces).
    **/
    public var annotationColorToggle:Null<AnnotationColor> = null;

    public function new() {}

    /**
        The color of an annotation started with `modifiers` held: the control row's color if one
        is selected, otherwise none - red, Shift - blue, Ctrl - green, Shift+Ctrl - yellow.
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

    /**
        Whether a promotion completed with `modifiers` held becomes a Dominator without asking.
    **/
    public function autoPromotes(modifiers:Modifiers):Bool
    {
        var byShift:Bool = autoPromoteMode == SHIFT && modifiers.shift;
        if (controlsShown)
            return autoPromoteToggle || byShift;
        return autoPromoteMode == ALWAYS || byShift;
    }

    /**
        Whether a premove that may become a chameleon capture, completed with `modifiers` held,
        asks which kind to morph into.
    **/
    public function asksChameleon(modifiers:Modifiers):Bool
    {
        return (controlsShown && askChameleonToggle) || modifiers.shift;
    }
}
