package net.ws.events;

import lib.std.Never;
import net.ws.channels.Everyone;
import lib.pubsub.IEvent;

class ServerShutdown implements IEvent<Never, Everyone>
{
}
