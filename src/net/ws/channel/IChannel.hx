package net.ws.channel;

@:autoBuild(net.ws.macros.ChannelMacro.build())
interface IChannel
{
	public function toJson():Dynamic;
	public function hash():String;
}
