package net.ws.channels;

import lib.pubsub.IChannel;

@:channelGroup('player.started_games')
class StartedPlayerGames implements IChannel
{
    public var watchedRef:String;
}
