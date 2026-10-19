package net.ws;

import easypubsub.Subscription;
import easypubsub.IChannel;
import easypubsub.PubSubEngine;

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

    /** Subscribes to every channel in a single message **/
    public static function subMany<T:IChannel>(channels:Array<T>):Array<Subscription<T>>
    {
        return _engine.subMany(channels);
    }

    /** Detaches every subscription in a single message **/
    public static function unsubMany<T:IChannel>(subscriptions:Array<Subscription<T>>):Void
    {
        _engine.unsubMany(subscriptions);
    }
}
