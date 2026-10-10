package net.models.game;

import morestd.DateTime;
import jsonmodel.IJsonUnserializableMacro;
import net.models.game.GameOutcomePublic;
import net.models.game.GameTimeUpdatePublic;
import net.models.common.TimeControlKind;
import net.models.common.UserRefWithNickname;
import net.models.common.FischerTimeControl;

class OngoingGamePublic implements IJsonUnserializableMacro
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
	@:default(null) public var fischer_time_control:Null<FischerTimeControl>;
	@:default(null) public var outcome:Null<GameOutcomePublic>;
	public var ply_cnt:Int;
	@:default(null) @:jcustomparse(jsonmodel.StdParsers.parseOptionalDate) public var last_ply_at:Null<DateTime>;
	@:default(null) public var latest_time_update:Null<GameTimeUpdatePublic>;
}
