package net.rest.models.challenge.response;

import lib.stdtypes.DateTime;
import net.rest.models.challenge.submodels.ChallengeAcceptorColor;
import net.rest.models.game.response.GamePublic;
import net.rest.models.common.TimeControl;
import net.rest.models.common.TimeControlKind;
import net.rest.models.common.UserRefWithNickname;
import net.rest.models.challenge.submodels.ChallengeKind;
import lib.json.IJsonUnserializableMacro;

class ChallengePublic implements IJsonUnserializableMacro
{
	public var id:Int;
	public var rated:Bool;
	public var acceptor_color:ChallengeAcceptorColor;
	@:default(null) public var custom_starting_sip:Null<String>;
	@:jcustomparse(lib.json.StdParsers.parseDate) public var created_at:DateTime;
	public var caller:UserRefWithNickname;
	@:default(null) public var callee:Null<UserRefWithNickname>;
	public var kind:ChallengeKind;
	public var time_control_kind:TimeControlKind;
	public var active:Bool;
	@:default(null) public var fischer_time_control:Null<TimeControl>;
	@:default(null) public var resulting_game:Null<GamePublic>;
}
