package net.ws.channel.groups;

@:channelGroup('player.started_games')
class StartedPlayerGames implements IChannel
{
    public var watchedRef:String;
}
