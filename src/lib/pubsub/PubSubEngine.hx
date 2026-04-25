package lib.pubsub;

import lib.std.Json as JsonUtils;
import lib.std.StringSetMap;
import lib.std.BackoffDelayTimer;
import hx.ws.Types.MessageType;
import js.html.Event;
import lib.std.DateTime;
import lib.std.RefreshableTimer;
import haxe.Json;
import hx.ws.WebSocket;

class PubSubEngine implements IPubSubEngine
{
	private var websocket:WebSocket;
	private var pingTimer:RefreshableTimer;
	private var reconnectTimer:BackoffDelayTimer;

	private var lastServerMessageUnixSecs:Int;

	public var activeSubscriptions:StringSetMap<Subscription<IChannel>> = new StringSetMap();
	public var connected(default, null):Bool = false;
	public var hasEverBeenConnected(default, null):Bool = false;

	private var tokenRetriever:Null<Void->Null<String>> = null;
	private var lastActivityUnixSecsRetriever:Null<Void->Null<Int>> = null;
	private var onInitialConnectionFailed:Null<Void->Void> = null;

	private var token(get, never):Null<String>;
	private var lastActivityUnixSecs(get, never):Null<Int>;

	public function new(url:String, ?onInitialConnectionFailed:Null<Void->Void> = null, ?tokenRetriever:Null<Void->Null<String>> = null,
			?lastActivityUnixSecsRetriever:Null<Void->Null<Int>> = null)
	{
		this.websocket = new WebSocket(url, false);
		this.pingTimer = new RefreshableTimer(30_000, heartbeatTick);
		this.reconnectTimer = new BackoffDelayTimer(1000, 1.5, 2, 16_000, -1000, 1000, connect.bind(null));

		this.onInitialConnectionFailed = onInitialConnectionFailed;
		this.tokenRetriever = tokenRetriever;
		this.lastActivityUnixSecsRetriever = lastActivityUnixSecsRetriever;
	}

	public function connect(?onInitialConnectionFailed:Null<Void->Void> = null)
	{
		if (onInitialConnectionFailed != null)
			this.onInitialConnectionFailed = onInitialConnectionFailed;

		websocket.onclose = onClose;
		websocket.onerror = onError;
		websocket.onmessage = onMessage;
		websocket.onopen = onOpen;

		lastServerMessageUnixSecs = DateTime.nowUnixSecs();

		websocket.open();
	}

	public function sendEvent(eventSlug:String, body:Null<{}> = null)
	{
		var message:{} = {event: eventSlug};
		if (token != null)
			Reflect.setField(message, "token", token);
		if (body != null)
			Reflect.setField(message, "body", body);
		websocket.send(Json.stringify(message));
	}

	public function sendSerializedEvent(eventSlug:String, serializedBody:String)
	{
		var message:String = '{"event":"$eventSlug","body":$serializedBody';
		if (token != null)
			message += ',"token":"$token"';
		message += "}";
		websocket.send(message);
	}

	private function sendSubOrUnsubEvent(channel:IChannel, sub:Bool)
	{
		var eventKind:String = sub ? "sub" : "unsub";
		sendEvent(eventKind, {channel: channel.toJson()});
	}

	public function sub<T:IChannel>(channel:T):Subscription<T>
	{
		var subscription:Subscription<T> = new Subscription(this, channel);
		activeSubscriptions.add(channel.hash(), cast subscription);
		sendSubOrUnsubEvent(channel, true);
		return subscription;
	}

	public function unsub<T:IChannel>(subscription:Subscription<T>)
	{
		var channelHash:String = subscription.channel.hash();
		activeSubscriptions.remove(channelHash, cast subscription);
		if (!activeSubscriptions.hasValues(channelHash))
			sendSubOrUnsubEvent(subscription.channel, false);
	}

	private function heartbeatTick()
	{
		sendEvent("ping", {last_activity: lastActivityUnixSecs});

		if (DateTime.nowUnixSecs() - lastServerMessageUnixSecs > 60)
			websocket.close();
	}

	private function onOpen()
	{
		connected = true;
		hasEverBeenConnected = true;

		reconnectTimer.reset();
		pingTimer.start();

		for (canonicalChannelJson in activeSubscriptions.keys())
			sendSerializedEvent("sub", canonicalChannelJson);
	}

	private function onMessage(msg:MessageType)
	{
		var strContent:String = switch msg
		{
			case BytesMessage(content):
				content.readAllAvailableBytes().toString();
			case StrMessage(content):
				content;
		};

		lastServerMessageUnixSecs = DateTime.nowUnixSecs();

		try
		{
			final rawData:Dynamic = Json.parse(strContent);
			final eventKind:String = Reflect.field(rawData, "event");
			final rawPayload:Dynamic = Reflect.field(rawData, "body");
			final channelJson:Dynamic = Reflect.field(rawData, "channel");
			final channelHash:String = JsonUtils.canonize(channelJson);
			for (subscription in activeSubscriptions.get(channelHash))
				subscription.dispatch(eventKind, rawPayload);
		}
		catch (e)
		{
			return;
		}
	}

	private function onClose()
	{
		connected = false;

		pingTimer.stop();
		reconnectTimer.startDelay();

		if (!hasEverBeenConnected && onInitialConnectionFailed != null)
			onInitialConnectionFailed();
	}

	private function onError(error:Event)
	{
		trace("Connection error: " + error.type);
	}

	private function get_token():Null<String>
	{
		return tokenRetriever != null ? tokenRetriever() : null;
	}

	private function get_lastActivityUnixSecs():Null<Int>
	{
		return lastActivityUnixSecsRetriever != null ? lastActivityUnixSecsRetriever() : null;
	}
}
