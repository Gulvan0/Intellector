package client.ui.games.flow;

import haxe.ui.events.UIEvent;
import haxefolio.form.plumbing.AutofillNeutralTextField;
import js.html.Element;
import js.html.Event;

/** A short input taking digits only, reporting edits and the loss of focus **/
class DigitField extends AutofillNeutralTextField
{
    private final onEdited:Void->Void;
    private var rendered:String = "";

    public var number(get, set):Null<Int>;

    public function new(maxDigits:Int, onEdited:Void->Void, onBlurred:Void->Void)
    {
        super();
        this.onEdited = onEdited;
        maxChars = maxDigits;
        addClass(StyleClass.GAMES_DIGIT_FIELD);
        onChange = onTextChanged;
        element.setAttribute("inputmode", "numeric");
        element.addEventListener("focusout", (_:Event) -> onBlurred());
    }

    /** Moves keyboard focus into the input, the field being on screen **/
    public function focusInput():Void
    {
        var input:Null<Element> = element.tagName == "INPUT" ? element : element.querySelector("input");
        if (input != null)
            input.focus();
    }

    /** Shows `value` zero-padded to `digits` **/
    public function showPadded(value:Int, digits:Int):Void
    {
        rendered = StringTools.lpad(Std.string(value), "0", digits);
        text = rendered;
    }

    private function onTextChanged(_:UIEvent):Void
    {
        var current:String = text ?? "";
        var digits:String = ~/[^0-9]/g.replace(current, "");
        if (digits != current)
            text = digits;
        if (digits == rendered)
            return;
        rendered = digits;
        onEdited();
    }

    private function get_number():Null<Int>
    {
        var current:String = text ?? "";
        return current == "" ? null : Std.parseInt(current);
    }

    private function set_number(newValue:Null<Int>):Null<Int>
    {
        rendered = newValue == null ? "" : Std.string(newValue);
        text = rendered;
        return newValue;
    }
}
