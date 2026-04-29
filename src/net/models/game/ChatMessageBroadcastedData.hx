package net.models.game;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;

class ChatMessageBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var occurred_at:DateTime;
	public var text:String;
	public var spectator:Bool;
	public var author:UserRefWithNickname;
}
