package gfx;

import haxe.ui.components.TextField;
import haxe.ui.components.Label;

class Factory 
{
    public static function makeLabel(text:String, ?isHTML:Bool = false, ?width:Float, ?textAlign:String = "left"):Label
    {
        var label:Label = new Label();
        if (isHTML)
            label.htmlText = text;
        else
            label.text = text;
        if (width != null)
            label.width = width;
        label.textAlign = textAlign;
        return label;
    }

    public static function makeInputField(width:Float, ?placeholder:String, ?restrictChars:String, ?password:Bool = false):TextField
    {
        var tf = new TextField();
        tf.width = width;
        if (placeholder != null)
		    tf.placeholder = placeholder;
        if (restrictChars != null)
            tf.restrictChars = restrictChars;
        tf.password = password;
        return tf;
    }
}