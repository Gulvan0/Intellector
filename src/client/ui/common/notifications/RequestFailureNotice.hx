package client.ui.common.notifications;

import client.datatypes.FailedAction;
import client.datatypes.RequestFailureReason;
import haxe.Timer;
import haxe.ui.components.Label;
import haxefolio.HaxeFolioApp;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;
import http.HttpError;

/**
    A toast telling the user that a request made on their behalf failed: the action as the title, the
    reason below it. Closed by its close control or after `LIFETIME_MS`. Showing a notice identical to
    one on screen restarts that one's timer instead of stacking another.
**/
class RequestFailureNotice
{
    private static inline final LIFETIME_MS:Int = 6000;

    private static var shown:Map<String, RequestFailureNotice> = [];

    private final key:String;
    private final card:NotificationCard;
    private final notification:Notification;
    private var timer:Null<Timer> = null;

    public static function show(action:FailedAction, reason:RequestFailureReason):Void
    {
        var key:String = '$action/${Std.string(reason)}';
        var existing:Null<RequestFailureNotice> = shown.get(key);

        if (existing != null)
            existing.restartTimer();
        else
            shown.set(key, new RequestFailureNotice(key, action, reason));
    }

    /** `show` with the reason told by `error` **/
    public static function showHttpError(action:FailedAction, error:HttpError):Void
    {
        show(action, reasonOf(error));
    }

    private static function reasonOf(error:HttpError):RequestFailureReason
    {
        var httpStatus:Null<Int> = error.httpStatus;

        if (httpStatus == null || httpStatus == 0)
            return NoConnection;
        else if (httpStatus >= 500)
            return ServerError(httpStatus);
        else
            return Unexpected;
    }

    private function new(key:String, action:FailedAction, reason:RequestFailureReason)
    {
        this.key = key;

        var reasonLabel:Label = new Label();
        reasonLabel.percentWidth = 100;
        reasonLabel.text = GroupedLocaleResolvers.requestFailureReason(reason);
        reasonLabel.addClass(StyleClass.REQUEST_FAILURE_REASON);

        card = new NotificationCard();
        card.title = GroupedLocaleResolvers.requestFailureTitle(action);
        card.onClose = dismiss;
        card.addComponent(reasonLabel);

        notification = HaxeFolioApp.notify(card, StyleVars.REQUEST_FAILURE_NOTICE_EXPANDED_WIDTH);
        restartTimer();
    }

    private function restartTimer():Void
    {
        if (timer != null)
            timer.stop();

        timer = Timer.delay(dismiss, LIFETIME_MS);
    }

    private function dismiss():Void
    {
        timer.stop();
        shown.remove(key);
        notification.dismiss();
        card.disposeComponent();
    }
}
