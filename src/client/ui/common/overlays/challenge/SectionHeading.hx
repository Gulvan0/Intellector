package client.ui.common.overlays.challenge;

import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;

/**
    A form section's title over a divider, with an optional control at its right end (a switch
    that belongs to the whole section).
**/
class SectionHeading extends HBox
{
    public function new(title:String, ?trailing:Component)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM_SECTION_HEADING);

        var titleLabel:Label = new Label();
        titleLabel.text = title;
        titleLabel.verticalAlign = "center";
        titleLabel.addClass(StyleClass.CHALLENGE_FORM_SECTION_TITLE);
        this.addComponent(titleLabel);

        if (trailing != null)
        {
            trailing.verticalAlign = "center";
            this.addComponent(trailing);
        }
    }
}
