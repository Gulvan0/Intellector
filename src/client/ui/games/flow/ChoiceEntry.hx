package client.ui.games.flow;

import haxe.ui.core.Component;

/** A line of a `ChoiceList` **/
enum ChoiceEntry<T>
{
    Heading(text:Void->String);
    Separator;
    /**
        A value picked (or ticked) on click. `symbol` is shown before the label in a column of its own
        (an operator's sign); a `disabledReason` disables the option and is shown beside it.
    **/
    Fixed(value:T, label:Void->String, ?icon:String, ?symbol:Void->String, ?disabledReason:Void->String);
    /**
        Opens a prompt for a value: `open` gets the option's row, to place the prompt beside, and the
        callback taking the value. `owns` tells the values it produces, to mark the option as chosen
        and to give a ticked value its icon.
    **/
    Appended(label:Void->String, icon:Null<String>, open:(Component, T->Void)->Void, owns:T->Bool);
}
