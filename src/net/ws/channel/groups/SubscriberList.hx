package net.ws.channel.groups;

class SubscriberList<InnerChannel:IChannel> implements IChannel
{
    public var channel:InnerChannel;
}
