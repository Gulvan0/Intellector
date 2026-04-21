package net.ws;

import net.ws.Subscription;
import net.ws.channel.IChannel;

interface IPubSubEngine
{
	public function sub<T:IChannel>(channel:T):Subscription<T>;
	public function unsub<T:IChannel>(subscription:Subscription<T>):Void;
}
