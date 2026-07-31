package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;
import net.models.common.FischerTimeControl;
import net.models.common.TimeControlKind;

class GameStartedBroadcastedData implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var started_at:DateTime;
	public var time_control_kind:TimeControlKind;
	public var rated:Bool;
	@:default(null) public var custom_starting_sip:Null<String>;
	@:default(null) public var external_uploader_ref:Null<String>;
	public var id:Int;
	public var white_player:UserRefWithNickname;
	public var black_player:UserRefWithNickname;
	@:default(null) public var fischer_time_control:Null<FischerTimeControl>;
}
