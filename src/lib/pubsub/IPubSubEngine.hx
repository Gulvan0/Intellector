package lib.pubsub;

interface IPubSubEngine
{
	public function sub<T:IChannel>(channel:T):Subscription<T>;
	public function unsub<T:IChannel>(subscription:Subscription<T>):Void;
}
