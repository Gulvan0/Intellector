package client.ui.common.notifications;

import client.datatypes.game.GameEnding;
import client.datatypes.game.LiveGameInfo;
import client.formatters.GameFormatters;
import haxe.Timer;
import haxe.ui.components.Label;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;
import intellectorboard.primitives.piece.PieceColor;

/** The result of a game that has just ended on the open page; closes by itself after `LIFETIME_MS` **/
class GameEndedNotice
{
    private static inline final LIFETIME_MS:Int = 8000;

    private final card:NotificationCard;
    private final notification:Notification;
    private final timer:Timer;

    /** `userColor`: the colour the user played, for their rating change; null for a spectator **/
    public static function show(info:LiveGameInfo, ending:GameEnding, userColor:Null<PieceColor>):Void
    {
        new GameEndedNotice(info, ending, userColor);
    }

    private function new(info:LiveGameInfo, ending:GameEnding, userColor:Null<PieceColor>)
    {
        var resolutionLabel:Label = new Label();
        resolutionLabel.percentWidth = 100;
        resolutionLabel.addClass(StyleClass.NOTICE_TEXT);
        LocaleManager.instance.registerComponent(resolutionLabel, "text", () -> GameFormatters.resolution(ending));

        card = new NotificationCard();
        card.title = LocaleUtils.localeBinding("intellector.game_ended_notice.title");
        card.onClose = dismiss;
        card.addComponent(resolutionLabel);

        var delta:Null<Int> = userColor != null ? ending.eloDelta(userColor) : null;
        var rating:Null<Int> = userColor != null && info.participant(userColor).rating != null ? info.participant(userColor).rating.elo : null;
        if (delta != null && rating != null)
        {
            var ratingLabel:Label = new Label();
            ratingLabel.percentWidth = 100;
            ratingLabel.addClass(StyleClass.NOTICE_TEXT);
            var newRating:Int = rating + delta;
            var deltaText:String = GameFormatters.eloDelta(delta);
            LocaleManager.instance.registerComponent(ratingLabel, "text", () -> LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.game_ended_notice.rating"), newRating, deltaText));
            card.addComponent(ratingLabel);
        }

        notification = HaxeFolioApp.notify(card, StyleVars.GAME_ENDED_NOTICE_EXPANDED_WIDTH);
        timer = Timer.delay(dismiss, LIFETIME_MS);
    }

    private function dismiss():Void
    {
        timer.stop();
        notification.dismiss();
        card.disposeComponent();
    }
}
