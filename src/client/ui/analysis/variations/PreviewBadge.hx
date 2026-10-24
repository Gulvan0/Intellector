package client.ui.analysis.variations;

import haxe.ui.components.Image;
import haxe.ui.containers.Box;

using client.ui.ComponentExtension;

/** The mark on the node a study's card shows: solid when chosen, dashed while it's the main line's end by default **/
class PreviewBadge extends Box
{
    private final image:Image;

    /** `inText`: the text view's plain icon after the notation, rather than the tree view's ring over a pill's corner **/
    public function new(inText:Bool)
    {
        super();
        addClass(inText ? StyleClass.VARIATION_PREVIEW_INLINE : StyleClass.VARIATION_PREVIEW_BADGE);
        verticalAlign = "center";
        element.style.pointerEvents = "none"; // a click goes to the node under it

        image = new Image();
        image.horizontalAlign = "center";
        image.verticalAlign = "center";
        addComponent(image);
        setAuto(false);
    }

    public function setAuto(auto:Bool):Void
    {
        this.setClass(StyleClass.VARIATION_PREVIEW_AUTO, auto);
        image.resource = Assets.analysisIcon(auto ? "card_preview_badge_auto" : "card_preview_badge");
    }
}
