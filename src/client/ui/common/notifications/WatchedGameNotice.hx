package client.ui.common.notifications;

import client.datatypes.game.OngoingGame;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;
import haxefolio.structure.ActionButton;

/**
    A notification offering to open a game the watched player has started. Stays until closed or the
    game is opened; a newer one replaces it.
**/
class WatchedGameNotice
{
    private static var shown:Null<WatchedGameNotice> = null;

    private final watchedNickname:String;
    private final game:OngoingGame;
    private final card:NotificationCard;
    private final notification:Notification;

    /** Kept if it's already shown for `game` **/
    public static function show(watchedNickname:String, game:OngoingGame):Void
    {
        if (shown != null && shown.game.id == game.id)
            return;

        if (shown != null)
            shown.dismiss();

        shown = new WatchedGameNotice(watchedNickname, game);
    }

    /** Dismisses the one shown for game `gameId`, if any **/
    public static function dismissFor(gameId:Int):Void
    {
        if (shown != null && shown.game.id == gameId)
            shown.dismiss();
    }

    private function new(watchedNickname:String, game:OngoingGame)
    {
        this.watchedNickname = watchedNickname;
        this.game = game;

        var textLabel:Label = new Label();
        textLabel.percentWidth = 100;
        textLabel.addClass(StyleClass.NOTICE_TEXT);
        LocaleManager.instance.registerComponent(textLabel, "text", resolveText); // a binding would parse the nickname as an expression

        card = new NotificationCard();
        LocaleManager.instance.registerComponent(card, "title", resolveTitle);
        card.onClose = dismiss;
        card.addComponent(textLabel);
        var openButton:ActionButton = new ActionButton(LocaleUtils.localeBinding("intellector.watched_game_notice.open"), null, true);
        PageLink.attach(openButton, PagePaths.liveGame(game.id), null, null, dismiss);
        card.addAction(openButton);

        notification = HaxeFolioApp.notify(card, StyleVars.WATCHED_GAME_NOTICE_EXPANDED_WIDTH);
    }

    private function resolveTitle():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watched_game_notice.title"), watchedNickname);
    }

    private function resolveText():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.watched_game_notice.text"), game.id, game.opponentNickname);
    }

    private function dismiss():Void
    {
        if (shown == this)
            shown = null;

        notification.dismiss();
        card.disposeComponent();
    }
}
