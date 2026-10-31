package client.ui.common.notifications;

import client.datatypes.request.FailedAction;
import client.datatypes.request.RequestFailureReason;
import haxe.Timer;
import haxe.ui.components.Label;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;
import haxefolio.structure.ActionButton;
import http.HttpError;
import net.models.common.RestErrorResponse;
import net.rest.RestErrors;

/**
    A toast telling the user that a request made on their behalf failed: the action as the title, the
    reason below it. Closed by its close control or after `LIFETIME_MS`; a notice with a retry action
    stays until closed or retried. Showing a notice identical to
    one on screen restarts that one's timer instead of stacking another.
**/
class RequestFailureNotice
{
    private static inline final LIFETIME_MS:Int = 6000;

    private static var shown:Map<String, RequestFailureNotice> = [];

    private final key:String;
    private final action:FailedAction;
    private final card:NotificationCard;
    private final notification:Notification;
    private var persistent:Bool = false;
    private var timer:Null<Timer> = null;

    /** `retry`: if given, the notice offers a button running it **/
    public static function show(action:FailedAction, reason:RequestFailureReason, ?retry:Void->Void):Void
    {
        var key:String = '$action/${Std.string(reason)}';
        var existing:Null<RequestFailureNotice> = shown.get(key);

        if (existing != null)
            existing.restartTimer();
        else
            shown.set(key, new RequestFailureNotice(key, action, reason, retry));
    }

    /** `show` with the reason told by `error` **/
    public static function showHttpError(action:FailedAction, error:HttpError, ?retry:Void->Void):Void
    {
        show(action, reasonOf(error), retry);
    }

    /** Closes every notice about `action` still on screen **/
    public static function dismissAll(action:FailedAction):Void
    {
        for (notice in Lambda.array(shown))
            if (notice.action == action)
                notice.dismiss();
    }

    private static function reasonOf(error:HttpError):RequestFailureReason
    {
        var httpStatus:Null<Int> = error.httpStatus;
        var codedReason:Null<RequestFailureReason> = codedReasonOf(RestErrors.responseOf(error));

        if (codedReason != null)
            return codedReason;
        else if (httpStatus == null || httpStatus == 0)
            return NoConnection;
        else if (httpStatus >= 500)
            return ServerError(httpStatus);
        else
            return Unexpected;
    }

    private static function codedReasonOf(response:Null<RestErrorResponse>):Null<RequestFailureReason>
    {
        if (response == null)
            return null;

        return switch response.code {
            case CHALLENGE_ALREADY_EXISTS: ChallengeAlreadyExists;
            case TOO_MANY_ACTIVE_CHALLENGES if (response.max_active_challenges != null): TooManyActiveChallenges(response.max_active_challenges);
            case TOO_MANY_DIRECT_CHALLENGES if (response.max_active_challenges != null): TooManyDirectChallenges(response.max_active_challenges);
            case SERVER_RESTARTING: ServerRestarting;
            default: null;
        }
    }

    private function new(key:String, action:FailedAction, reason:RequestFailureReason, retry:Null<Void->Void>)
    {
        this.key = key;
        this.action = action;

        var reasonLabel:Label = new Label();
        reasonLabel.percentWidth = 100;
        reasonLabel.text = GroupedLocaleResolvers.requestFailureReason(reason);
        reasonLabel.addClass(StyleClass.NOTICE_TEXT);

        card = new NotificationCard();
        card.addClass(StyleClass.ERROR_NOTICE);
        card.title = GroupedLocaleResolvers.requestFailureTitle(action);
        card.onClose = dismiss;
        card.addComponent(reasonLabel);

        if (retry != null)
        {
            var retryButton:ActionButton = new ActionButton(LocaleUtils.localeBinding("intellector.request_failure.retry"), null, true);
            retryButton.onClick = _ -> {
                dismiss();
                retry();
            };
            card.addAction(retryButton);
        }

        notification = HaxeFolioApp.notify(card, StyleVars.REQUEST_FAILURE_NOTICE_EXPANDED_WIDTH);
        persistent = retry != null;
        restartTimer();
    }

    private function restartTimer():Void
    {
        if (timer != null)
            timer.stop();

        if (!persistent)
            timer = Timer.delay(dismiss, LIFETIME_MS);
    }

    private function dismiss():Void
    {
        if (timer != null)
            timer.stop();
        shown.remove(key);
        notification.dismiss();
        card.disposeComponent();
    }
}
