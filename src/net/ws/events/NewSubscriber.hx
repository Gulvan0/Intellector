package net.ws.events;

import net.models.common.UserRefWithNickname;
import net.ws.channels.SubscriberList;
import lib.pubsub.IEvent;

class NewSubscriber implements IEvent<Null<UserRefWithNickname>, SubscriberList<Dynamic>>
{
}
