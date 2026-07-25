package net.ws.channels;

import easypubsub.IChannel;

class SubscriberList<InnerChannel:IChannel> implements IChannel
{
    public var channel:InnerChannel;
}
