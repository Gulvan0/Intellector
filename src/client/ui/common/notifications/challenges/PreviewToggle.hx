package client.ui.common.notifications.challenges;

import haxe.ui.components.Button;
import haxefolio.LocaleUtils;

/** The Preview button of a custom position; selected while its preview is open **/
class PreviewToggle extends Button
{
    public function new(onPress:Void->Void)
    {
        super();

        text = LocaleUtils.localeBinding("intellector.challenge_notification.preview");
        addClass(StyleClass.CHALLENGE_PREVIEW_TOGGLE);
        onClick = _ -> onPress();
    }
}
