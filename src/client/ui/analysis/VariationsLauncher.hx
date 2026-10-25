package client.ui.analysis;

import client.ui.game.GameButtons;
import haxe.ui.components.Button;
import haxe.ui.containers.VBox;

/** Short medium layout: the card standing in for the variations, whose button expands them to the whole area **/
class VariationsLauncher extends VBox
{
    public function new(onOpen:Void->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_ACTIONS_CARD);

        var button:Button = GameButtons.actionWithIcon(Assets.analysisIcon("expand"), "intellector.analysis.variations.title", onOpen);
        button.percentWidth = 100;
        addComponent(button);
    }
}
