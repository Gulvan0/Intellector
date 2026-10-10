package client.ui.common.notifications;

import client.datatypes.StartedGame;
import haxe.ui.components.Label;
import haxe.ui.locale.LocaleManager;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.notification.Notification;
import haxefolio.notification.NotificationCard;
import haxefolio.structure.ActionButton;

/**
    A notification offering to open a game that has started while the user is busy with another one.
    Stays until closed or the game is opened from it.
**/
class GameStartedNotice
{
    private final game:StartedGame;
    private final textLabel:Label;
    private final card:NotificationCard;
    private final notification:Notification;

    public static function show(game:StartedGame):Void
    {
        new GameStartedNotice(game);
    }

    private function new(game:StartedGame)
    {
        this.game = game;

        textLabel = new Label();
        textLabel.percentWidth = 100;
        textLabel.addClass(StyleClass.NOTICE_TEXT);
        LocaleManager.instance.registerComponent(textLabel, "text", resolveText); // a binding would parse the nickname as an expression

        card = new NotificationCard();
        card.title = LocaleUtils.localeBinding("intellector.game_started_notice.title");
        card.onClose = dismiss;
        card.addComponent(textLabel);
        card.addAction(new ActionButton(LocaleUtils.localeBinding("intellector.game_started_notice.open"), open, true));

        notification = HaxeFolioApp.notify(card, StyleVars.GAME_STARTED_NOTICE_EXPANDED_WIDTH);
    }

    private function resolveText():String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.game_started_notice.text"), game.id, game.opponentNickname);
    }

    private function open():Void
    {
        dismiss();
        HaxeFolioApp.navigateTo('live/${game.id}');
    }

    private function dismiss():Void
    {
        notification.dismiss();
        card.disposeComponent();
    }
}
