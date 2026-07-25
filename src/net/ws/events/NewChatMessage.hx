package net.ws.events;

import net.models.game.ChatMessageBroadcastedData;
import net.ws.channels.Game;
import easypubsub.IEvent;

class NewChatMessage implements IEvent<ChatMessageBroadcastedData, Game>
{
}
