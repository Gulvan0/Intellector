package net.models.game;

import lib.std.DateTime;
import lib.json.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;
import net.models.common.TimeControl;
import net.models.common.TimeControlKind;

class GameStartedBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(lib.json.StdParsers.parseDate) public var started_at:DateTime;
	public var time_control_kind:TimeControlKind;
	public var rated:Bool;
	@:default(null) public var custom_starting_sip:Null<String>;
	@:default(null) public var external_uploader_ref:Null<String>;
	public var id:Int;
	public var white_player:UserRefWithNickname;
	public var black_player:UserRefWithNickname;
	@:default(null) public var fischer_time_control:Null<TimeControl>;
}
