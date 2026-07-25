package net.ws.events;

import morestd.Never;
import net.ws.channels.Everyone;
import easypubsub.IEvent;

class ServerShutdown implements IEvent<Never, Everyone>
{
}
