package lib.pubsub;

import lib.std.Never;
import lib.std.StringSetMap;
import lib.json.JsonUnserializable;

using lib.std.extensions.StringExtension;

class Subscription<TChannel:IChannel>
{
	private final engine:IPubSubEngine;

	public final channel:TChannel;

	private final handlers:StringSetMap<Dynamic->Void> = new StringSetMap();
	private final anyEventHandlers:Array<String->Dynamic->Void> = [];

	public function new(engine:IPubSubEngine, channel:TChannel)
	{
		this.engine = engine;
		this.channel = channel;
	}

	private function getEventKind<T>(kind:Class<IEvent<T, TChannel>>):String
	{
		return Type.getClassName(kind).lastDelimitedPart(".").toSnakeCase();
	}

	@:generic
	public function onEvent<TPayload:JsonUnserializable>(kind:Class<IEvent<TPayload, TChannel>>, handler:TPayload->Subscription<TChannel>->Void):Subscription<TChannel>
	{
		function callback(rawPayload:Dynamic)
		{
			handler(new TPayload(RawJson(rawPayload)), this);
		}

		handlers.add(getEventKind(kind), callback);

		return this;
	}

	public function onAtomicEvent(kind:Class<IEvent<Never, TChannel>>, handler:Subscription<TChannel>->Void):Subscription<TChannel>
	{
		function callback(_:Dynamic)
		{
			handler(this);
		}

		handlers.add(getEventKind(kind), callback);

		return this;
	}

	@:generic
	public function onEventLight<TPayload:JsonUnserializable>(kind:Class<IEvent<TPayload, TChannel>>, handler:TPayload->Void):Subscription<TChannel>
	{
		function callback(rawPayload:Dynamic)
		{
			handler(new TPayload(RawJson(rawPayload)));
		}

		handlers.add(getEventKind(kind), callback);

		return this;
	}

	public function onAtomicEventLight(kind:Class<IEvent<Never, TChannel>>, handler:Void->Void):Subscription<TChannel>
	{
		function callback(_:Dynamic)
		{
			handler();
		}

		handlers.add(getEventKind(kind), callback);

		return this;
	}

	public function onAnyEvent(handler:String->Dynamic->Void):Subscription<TChannel>
	{
		anyEventHandlers.push(handler);
		return this;
	}

	public function dropAllHandlers<T>(kind:Null<Class<IEvent<T, TChannel>>> = null)
	{
		if (kind == null) {
			handlers.clear();
			anyEventHandlers.resize(0);
		} else {
			handlers.removeAll(getEventKind(kind));
		}
	}

	@:allow(lib.pubsub.PubSubEngine)
	private function dispatch(eventKind:String, rawPayload:Dynamic)
	{
		for (handler in handlers.get(eventKind))
			handler(rawPayload);
		for (handler in anyEventHandlers)
			handler(eventKind, rawPayload);
	}

	public function branch():Subscription<TChannel>
	{
		return engine.sub(channel);
	}

	public function detach()
	{
		engine.unsub(this);
	}
}
