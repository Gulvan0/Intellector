package client.ui.games.flow;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/** A step's Confirm button, after a line telling what will be confirmed **/
class StepFooter extends HBox
{
    private final infoLabel:Label;
    private final button:HBox;

    public var enabled(default, set):Bool = true;
    /** Interpreted like any `.text` **/
    public var info(get, set):String;

    public function new(onConfirm:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAMES_STEP_FOOTER);

        infoLabel = new Label();
        infoLabel.percentWidth = 100;
        infoLabel.addClass(StyleClass.GAMES_STEP_FOOTER_INFO);
        infoLabel.verticalAlign = "center";
        addComponent(infoLabel);

        button = new HBox();
        button.addClass(StyleClass.GAMES_CONFIRM_BUTTON);
        button.verticalAlign = "center";
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> {
            if (enabled)
                onConfirm();
        });
        addComponent(button);

        var caption:Label = new Label();
        caption.text = LocaleUtils.localeBinding("intellector.games.step.confirm");
        caption.addClass(StyleClass.GAMES_CONFIRM_BUTTON_TEXT);
        caption.verticalAlign = "center";
        button.addComponent(caption);
    }

    /** Shows `info` as a value, in the monospaced font, rather than as a remark **/
    public function setInfoMono(mono:Bool):Void
    {
        infoLabel.setClass(StyleClass.GAMES_STEP_FOOTER_VALUE, mono);
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        button.setClass(StyleClass.GAMES_CONFIRM_BUTTON_DISABLED, !value);
        return value;
    }

    private function get_info():String
    {
        return infoLabel.text;
    }

    private function set_info(value:String):String
    {
        infoLabel.text = value;
        return value;
    }
}
