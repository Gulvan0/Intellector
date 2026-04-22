package net.ws.channels;

import lib.pubsub.IChannel;

class SubscriberList<InnerChannel:IChannel> implements IChannel
{
    public var channel:InnerChannel;
}
