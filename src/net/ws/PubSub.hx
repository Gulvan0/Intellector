package net.ws;

import lib.pubsub.Subscription;
import lib.pubsub.IChannel;
import lib.pubsub.PubSubEngine;

class PubSub
{
    private static var _engine:PubSubEngine;

    public static function start(
        tokenRetriever:()->Null<String>,
        lastActivityUnixSecsRetriever:()->Null<Int>,
        ?onInitialConnectionFailed:Null<()->Void> = null
    )
    {
        _engine = new PubSubEngine(Config.getWebsocketUrl(), onInitialConnectionFailed, tokenRetriever, lastActivityUnixSecsRetriever);
        _engine.connect();
    }

    public static function isConnected():Bool
    {
        return _engine.connected;
    }

    public static function sub<T:IChannel>(channel:T):Subscription<T>
    {
        return _engine.sub(channel);
    }
}
