package net.models.game;

import net.models.game.GameOutcomePublic;
import net.models.common.TimeControlKind;
import net.models.common.UserRefWithNickname;
import net.models.common.TimeControl;
import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;

class GameSummaryPublic implements IJsonUnserializableMacro
{
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var started_at:DateTime;
	public var time_control_kind:TimeControlKind;
	public var rated:Bool;
	@:default(null) public var custom_starting_sip:Null<String>;
	@:default(null) public var external_uploader_ref:Null<String>;
	public var id:Int;
	public var white_player:UserRefWithNickname;
	public var black_player:UserRefWithNickname;
	public var opening_sip:String;
	public var latest_sip:String;
	@:default(null) public var fischer_time_control:Null<TimeControl>;
	@:default(null) public var outcome:Null<GameOutcomePublic>;
}
