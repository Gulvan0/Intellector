package client.ui.common.notifications;

import haxe.Timer;
import haxe.ui.components.Label;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;

/**
    A toast telling the user that the player they've just challenged is offline, so the challenge
    waits for them. Closed by its close control or after `LIFETIME_MS`.
**/
class CalleeOfflineNotice
{
    private static inline final LIFETIME_MS:Int = 6000;

    private final calleeNickname:String;
    private final card:NotificationCard;
    private final notification:Notification;
    private final timer:Timer;

    public static function show(calleeNickname:String):Void
    {
        new CalleeOfflineNotice(calleeNickname);
    }

    private function new(calleeNickname:String)
    {
        this.calleeNickname = calleeNickname;

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.addClass(StyleClass.NOTICE_TEXT);
        LocaleManager.instance.registerComponent(textLabel, "text", resolveText); // a binding would parse the nickname as an expression

        card = new NotificationCard();
        card.title = LocaleUtils.localeBinding("intellector.callee_offline_notice.title");
        card.onClose = dismiss;
        card.addComponent(textLabel);

        notification = HaxeFolioApp.notify(card, StyleVars.CALLEE_OFFLINE_NOTICE_EXPANDED_WIDTH);
        timer = Timer.delay(dismiss, LIFETIME_MS);
    }

    private function resolveText():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.callee_offline_notice.text"), calleeNickname);
    }

    private function dismiss():Void
    {
        timer.stop();
        notification.dismiss();
        card.disposeComponent();
    }
}
