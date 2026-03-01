package net.ws;

@:using(net.ws.EventChannelExtension)
enum EventChannel
{
    EveryoneEventChannel;
    PublicChallengeListEventChannel;
    GameListEventChannel;
    IncomingChallengesEventChannel(user_ref:String);
    OutgoingChallengesEventChannel(user_ref:String);
    GameEventChannel(game_id:Int);
    StartedPlayerGamesEventChannel(watched_ref:String);
    SubscriberListEventChannel(channel:EventChannel);
}
