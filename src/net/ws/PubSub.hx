package net.ws;

import easypubsub.Subscription;
import easypubsub.SubscriptionGroup;
import easypubsub.IChannel;
import easypubsub.PubSubEngine;
import net.ws.channels.Everyone;

using StringTools;

class PubSub
{
    private static var _engine:PubSubEngine;

    public static function start(
        tokenRetriever:()->Null<String>,
        lastActivityUnixSecsRetriever:()->Null<Int>,
        ?onInitialConnectionFailed:Null<()->Void> = null,
        ?onAuthError:Null<()->Void> = null
    )
    {
        _engine = new PubSubEngine(Config.getWebsocketUrl(), onInitialConnectionFailed, tokenRetriever, lastActivityUnixSecsRetriever);
        _engine.onAuthError = onAuthError;
        // the server subscribes before it computes the refresh, so the events preceding it are already reflected in it
        _engine.snapshotEventKind = kind -> kind.endsWith("_refresh");
        _engine.expectsSnapshot = channel -> !Std.isOfType(channel, Everyone);
        _engine.connect();
    }

    /** Makes the server see the connection under the current token, and with the current subscriptions **/
    public static function reauth():Void
    {
        _engine.reauth();
    }

    public static function isConnected():Bool
    {
        return _engine.connected;
    }

    /** Tells the server about the latest user activity without waiting for the next scheduled heartbeat **/
    public static function sendHeartbeat():Void
    {
        _engine.sendHeartbeat();
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

    /** Same as `subMany`, with the handlers attached once for all channels via the returned group **/
    public static function subGroup<T:IChannel>(channels:Array<T>):SubscriptionGroup<T>
    {
        return _engine.subGroup(channels);
    }

    /** Detaches every subscription in a single message **/
    public static function unsubMany<T:IChannel>(subscriptions:Array<Subscription<T>>):Void
    {
        _engine.unsubMany(subscriptions);
    }
}
