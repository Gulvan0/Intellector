package client.ui.common.notifications.challenges;

import haxe.ui.containers.HBox;
import haxefolio.LocaleUtils;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/common/notifications/challenge_stack_bar.xml"))
class ChallengeStackBar extends HBox
{
    public function new(collapsed:Bool, onDeclineAll:Void->Void, onHideAll:Void->Void)
    {
        super();

        if (collapsed)
            addClass(StyleClass.CHALLENGE_BAR_COLLAPSED);

        declineAllButton.onClick = _ -> onDeclineAll();
        hideAllButton.onClick = _ -> onHideAll();
    }

    /** Shows the total and how many have no row, if any **/
    public function setCounts(total:Int, withoutRow:Int):Void
    {
        countLabel.text = LocaleUtils.localeBinding("intellector.challenge_notification.count", '$total', '$withoutRow');
    }
}
