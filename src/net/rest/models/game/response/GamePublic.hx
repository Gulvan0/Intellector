package net.rest.models.game.response;

import net.rest.models.game.submodels.GameEvent;
import lib.stdtypes.DateTime;
import lib.json.IJsonUnserializableMacro;

class GamePublic implements IJsonUnserializableMacro
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
	@:default(null) public var outcome:Null<GameOutcomePublic>;
	@:jcustomparse(net.rest.models.game.SpecialParsers.parseGenericEventList) public var events:Array<GameEvent>;
	@:default(null) public var latest_time_update:Null<GameTimeUpdatePublic>;
}
