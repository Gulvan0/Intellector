package client.ui.common.notifications;

import haxe.Timer;
import haxe.ui.components.Label;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;

/** A toast with a title and a line of text. Closed by its close control, or after `lifetimeMs` if given **/
class InfoNotice
{
    private final card:NotificationCard;
    private final notification:Notification;
    private var timer:Null<Timer> = null;

    /** `titleKey` and `textKey` are locale keys **/
    public static function show(titleKey:String, textKey:String, ?lifetimeMs:Int):Void
    {
        new InfoNotice(titleKey, textKey, lifetimeMs);
    }

    private function new(titleKey:String, textKey:String, lifetimeMs:Null<Int>)
    {
        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.addClass(StyleClass.NOTICE_TEXT);
        textLabel.text = LocaleUtils.localeBinding(textKey);

        card = new NotificationCard();
        card.title = LocaleUtils.localeBinding(titleKey);
        card.onClose = dismiss;
        card.addComponent(textLabel);

        notification = HaxeFolioApp.notify(card, StyleVars.INFO_NOTICE_EXPANDED_WIDTH);
        if (lifetimeMs != null)
            timer = Timer.delay(dismiss, lifetimeMs);
    }

    private function dismiss():Void
    {
        if (timer != null)
            timer.stop();
        notification.dismiss();
        card.disposeComponent();
    }
}
