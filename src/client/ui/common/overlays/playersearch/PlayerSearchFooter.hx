package client.ui.common.overlays.playersearch;

import client.datatypes.player.PlayerStatus;
import client.ui.common.StatusDot;
import haxe.ui.components.Label;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;
import haxefolio.structure.ActionButton;

/** The legend of the status dots, wrapping onto a second line when narrow, and Cancel **/
class PlayerSearchFooter extends HBox
{
    public function new(onCancel:Void->Void)
    {
        super();
        percentWidth = 100;
        percentHeight = 100;
        addClass(StyleClass.PLAYER_SEARCH_FOOTER);

        var legend:ContinuousHBox = new ContinuousHBox();
        legend.percentWidth = 100;
        legend.verticalAlign = "center";
        legend.addClass(StyleClass.PLAYER_SEARCH_LEGEND);
        for (status in PlayerStatus.createAll())
            legend.addComponent(legendItem(status));
        addComponent(legend);

        var cancelButton:ActionButton = new ActionButton(LocaleUtils.localeBinding("intellector.overlay.player_search.cancel"), onCancel);
        cancelButton.verticalAlign = "center";
        cancelButton.addClass(StyleClass.PLAYER_SEARCH_CANCEL);
        addComponent(cancelButton);
    }

    private static function legendItem(status:PlayerStatus):HBox
    {
        var item:HBox = new HBox();
        item.addClass(StyleClass.PLAYER_SEARCH_LEGEND_ITEM);
        item.addComponent(new StatusDot(status));

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding('intellector.overlay.player_search.legend.${status.getName().toLowerCase()}');
        label.verticalAlign = "center";
        label.addClass(StyleClass.PLAYER_SEARCH_LEGEND_LABEL);
        item.addComponent(label);

        return item;
    }
}
