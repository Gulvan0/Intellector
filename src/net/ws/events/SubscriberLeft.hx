package net.ws.events;

import net.models.common.UserRefWithNickname;
import net.ws.channels.SubscriberList;
import easypubsub.IEvent;

class SubscriberLeft implements IEvent<Null<UserRefWithNickname>, SubscriberList<Dynamic>>
{
}
