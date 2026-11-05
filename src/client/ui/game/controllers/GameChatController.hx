package client.ui.game.controllers;

import client.auth.IdentityKeeper;
import client.datatypes.game.GameChatEntry;
import client.datatypes.game.GameChatMessage;
import client.datatypes.request.FailedAction;
import client.ui.common.notifications.RequestFailureNotice;
import client.ui.game.ChatCard;
import client.ui.game.GameLayout;
import net.models.game.GameSendChatMessagePayload;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** Shows the game's chat, as far as the user may see it, and sends the user's messages **/
class GameChatController
{
    private final session:LiveGameSession;
    private final chatCard:ChatCard;
    private final gameLayout:GameLayout;

    public function new(session:LiveGameSession, chatCard:ChatCard, gameLayout:GameLayout)
    {
        this.session = session;
        this.chatCard = chatCard;
        this.gameLayout = gameLayout;
    }

    public function refresh():Void
    {
        var entries:Array<GameChatEntry> = session.state.getChat().filter(isVisible);
        chatCard.setEntries(entries);

        var latestMessage:Null<GameChatMessage> = null;
        for (entry in entries)
        {
            switch entry
            {
                case Message(message):
                    latestMessage = message;
                default:
            }
        }
        gameLayout.setLatestMessage(latestMessage, false);
    }

    /** `appended`: the entry added at the end, or null if the chat changed otherwise **/
    public function onChanged(appended:Null<GameChatEntry>):Void
    {
        if (appended == null)
        {
            refresh();
            return;
        }

        if (!isVisible(appended))
            return;

        chatCard.appendEntry(appended);
        switch appended
        {
            case Message(message):
                gameLayout.setLatestMessage(message, message.authorRef != IdentityKeeper.currentIdentity.getUserRef());
            default:
        }
    }

    public function send(text:String):Void
    {
        Rest.client().execute(
            RestOperationRegistry.GAME_SEND_CHAT_MESSAGE,
            _ -> chatCard.clearDraft(),
            RequestFailureNotice.showHttpError.bind(SEND_CHAT_MESSAGE),
            null,
            null,
            ({game_id: session.gameId, text: text} : GameSendChatMessagePayload)
        );
    }

    // a player can't see spectators' messages until the game is over
    private function isVisible(entry:GameChatEntry):Bool
    {
        return switch entry {
            case Message(message): !message.spectator || !session.isPlaying();
            default: true;
        }
    }
}
