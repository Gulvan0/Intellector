package client.ui.profile;

import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.events.MouseEvent;

using client.ui.ComponentExtension;

/**
    A card of the aside: titled while the aside is a column; once it is above the games, a one-line
    bar with a chevron that expands and collapses the body, collapsed at first.
**/
class AsideCard extends VBox
{
    private final titleLabel:Label;
    private final toggleBar:HBox;
    private final chevron:Image;
    private final body:VBox;

    private var collapsible:Bool = false;
    private var expanded:Bool = false;

    /** `title` is a locale binding **/
    public function new(title:String)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.PROFILE_CARD);
        addClass(StyleClass.PROFILE_ASIDE_CARD);

        titleLabel = new Label();
        titleLabel.text = title;
        titleLabel.addClass(StyleClass.PROFILE_CARD_TITLE);
        addComponent(titleLabel);

        toggleBar = new HBox();
        toggleBar.percentWidth = 100;
        toggleBar.addClass(StyleClass.PROFILE_ASIDE_TOGGLE);
        toggleBar.trackHover();
        toggleBar.registerEvent(MouseEvent.CLICK, _ -> setExpanded(!expanded));
        addComponent(toggleBar);

        var toggleLabel:Label = new Label();
        toggleLabel.text = title;
        toggleLabel.percentWidth = 100;
        toggleLabel.addClass(StyleClass.PROFILE_ASIDE_TOGGLE_TEXT);
        toggleLabel.verticalAlign = "center";
        toggleBar.addComponent(toggleLabel);

        chevron = new Image();
        chevron.width = 14;
        chevron.height = 14;
        chevron.verticalAlign = "center";
        toggleBar.addComponent(chevron);

        body = new VBox();
        body.percentWidth = 100;
        body.addClass(StyleClass.PROFILE_ASIDE_BODY);
        addComponent(body);

        render();
    }

    public function setTier(tier:ProfileLayoutTier):Void
    {
        var nowCollapsible:Bool = tier != Wide;
        if (nowCollapsible != collapsible)
            expanded = false;
        collapsible = nowCollapsible;
        render();
    }

    private function setExpanded(expanded:Bool):Void
    {
        this.expanded = expanded;
        render();
    }

    private function render():Void
    {
        titleLabel.hidden = collapsible;
        toggleBar.hidden = !collapsible;
        body.hidden = collapsible && !expanded;
        chevron.resource = Assets.profileIcon(expanded ? "chevron_expanded" : "chevron_right");
    }
}
