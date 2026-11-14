package client.ui.games.flow;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import haxe.ui.locale.LocaleManager;

using client.ui.ComponentExtension;

/** A step's title, after a ← button when the step can be left backwards, or before a cancelling cross **/
class StepHeader extends HBox
{
    public function new(title:Void->String, ?back:Void->Void, ?cancel:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAMES_STEP_HEADER);

        if (back != null)
            addComponent(iconButton("back", back));

        var label:Label = new Label();
        label.percentWidth = 100;
        label.addClass(StyleClass.GAMES_STEP_TITLE);
        label.verticalAlign = "center";
        LocaleManager.instance.registerComponent(label, "text", title);
        addComponent(label);

        if (cancel != null)
            addComponent(iconButton("close", cancel));
    }

    private static function iconButton(icon:String, onClick:Void->Void):Box
    {
        var button:Box = new Box();
        button.addClass(StyleClass.GAMES_ICON_BUTTON);
        button.verticalAlign = "center";
        button.trackHover();
        button.registerEvent(MouseEvent.CLICK, _ -> onClick());

        var image:Image = new Image();
        image.resource = Assets.gamesIcon(icon);
        image.horizontalAlign = "center";
        image.verticalAlign = "center";
        button.addComponent(image);
        return button;
    }
}
