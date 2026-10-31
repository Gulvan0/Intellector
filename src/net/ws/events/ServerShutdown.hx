package net.ws.events;

import jsonmodel.UnserializableNull;
import net.ws.channels.Everyone;
import easypubsub.IEvent;

class ServerShutdown implements IEvent<UnserializableNull, Everyone>
{
}
