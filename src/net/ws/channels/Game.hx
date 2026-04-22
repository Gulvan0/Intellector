package net.ws.channels;

import lib.pubsub.IChannel;

@:channelGroup('game.main')
class Game implements IChannel
{
    public var gameId:Int;
}
