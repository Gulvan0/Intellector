package net.ws;

import easypubsub.Subscription;
import easypubsub.SubscriptionGroup;
import easypubsub.IChannel;
import easypubsub.PubSubEngine;

class PubSub
{
    /** The server closes a connection with this code, and its API version as the reason, when the version the client announced differs from its own **/
    public static inline final API_MISMATCH_CLOSE_CODE:Int = 4409;

    private static var _engine:PubSubEngine;

    public static function start(
        tokenRetriever:()->Null<String>,
        lastActivityUnixSecsRetriever:()->Null<Int>,
        ?onInitialConnectionFailed:Null<()->Void> = null,
        ?onAuthError:Null<()->Void> = null
    )
    {
        _engine = new PubSubEngine(Config.getWebsocketUrl(), onInitialConnectionFailed, tokenRetriever, lastActivityUnixSecsRetriever, 6000);
        _engine.onAuthError = onAuthError;
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

    /** `onDisconnected` is also called after each failed attempt to connect **/
    public static function watchConnection(onConnected:()->Void, onDisconnected:()->Void):Void
    {
        _engine.onConnected = onConnected;
        _engine.onDisconnected = onDisconnected;
    }

    /** `handler` gets the code and reason the server (or the network) closed an open connection with **/
    public static function watchClose(handler:Int->String->Void):Void
    {
        _engine.onClosed = handler;
    }

    /** `handler` gets a description and the caught error when a message can't be processed or an event handler throws **/
    public static function watchMessageFailures(handler:String->Dynamic->Void):Void
    {
        _engine.onMessageFailed = handler;
    }

    /** Attempts to connect right away instead of waiting out the reconnection delay **/
    public static function reconnectNow():Void
    {
        _engine.reconnectNow();
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

    /** Handlers for a channel the server delivers to every connection unasked (`Everyone`); nothing is sent to it **/
    public static function listen<T:IChannel>(channel:T):Subscription<T>
    {
        return _engine.listen(channel);
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
