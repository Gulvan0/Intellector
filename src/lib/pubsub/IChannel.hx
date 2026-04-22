package lib.pubsub;

@:autoBuild(lib.pubsub.macros.ChannelMacro.build())
interface IChannel
{
	public function toJson():Dynamic;
	public function hash():String;
}
