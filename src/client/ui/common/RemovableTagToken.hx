package client.ui.common;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;

using client.ui.ComponentExtension;

/**
    A study tag shown as a token with a cross that removes it. Both the token's parts are centered
    by alignment alone: the cross's style must not carry a margin to nudge it, since a margin
    stacks with the centering and pushes the cross off the token's middle line.
**/
class RemovableTagToken extends HBox
{
    public function new(tag:String, removeTooltip:String, onRemove:Void->Void)
    {
        super();
        addClass(StyleClass.STUDY_TOKEN);
        verticalAlign = "center";

        var text:Label = new Label();
        text.text = tag;
        text.verticalAlign = "center";
        text.addClass(StyleClass.STUDY_TOKEN_TEXT);
        addComponent(text);

        var removeButton:Box = new Box();
        removeButton.addClass(StyleClass.STUDY_TOKEN_REMOVE);
        removeButton.tooltip = removeTooltip;
        removeButton.verticalAlign = "center";
        removeButton.trackHover();
        removeButton.onClick = _ -> onRemove();
        addComponent(removeButton);

        var cross:Image = new Image();
        cross.resource = Assets.profileIcon("remove_tag");
        cross.width = 10;
        cross.height = 10;
        cross.horizontalAlign = "center";
        cross.verticalAlign = "center";
        removeButton.addComponent(cross);
    }
}
