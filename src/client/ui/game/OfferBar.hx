package client.ui.game;

import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;

/** A request over the board's top edge: a line of text and its answers **/
class OfferBar extends HBox
{
    private final textLabel:Label;

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_OFFER_BAR);

        textLabel = new Label();
        textLabel.percentWidth = 100;
        textLabel.verticalAlign = "center";
        textLabel.addClass(StyleClass.GAME_OFFER_TEXT);
        addComponent(textLabel);
    }

    public function setText(text:String):Void
    {
        textLabel.text = text;
    }

    /** `primary`: the filled, accent button **/
    public function addAnswer(caption:String, primary:Bool, onPress:Void->Void):Button
    {
        var button:Button = new Button();
        button.text = caption;
        button.verticalAlign = "center";
        button.addClass(StyleClass.GAME_BUTTON);
        if (primary)
            button.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        button.onClick = _ -> onPress();
        addComponent(button);
        return button;
    }
}
