package net.models.challenge;

import morestd.DateTime;
import net.models.challenge.ChallengeAcceptorColor;
import net.models.game.GameSummaryPublic;
import net.models.common.TimeControl;
import net.models.common.TimeControlKind;
import net.models.common.UserRefWithNickname;
import net.models.challenge.ChallengeKind;
import jsonmodel.IJsonUnserializableMacro;

class ChallengePublic implements IJsonUnserializableMacro
{
	public var id:Int;
	public var rated:Bool;
	public var acceptor_color:ChallengeAcceptorColor;
	@:default(null) public var custom_starting_sip:Null<String>;
	@:jcustomparse(jsonmodel.StdParsers.parseDate) public var created_at:DateTime;
	public var caller:UserRefWithNickname;
	@:default(null) public var callee:Null<UserRefWithNickname>;
	public var kind:ChallengeKind;
	public var time_control_kind:TimeControlKind;
	public var active:Bool;
	@:default(null) public var fischer_time_control:Null<TimeControl>;
	@:default(null) public var resulting_game:Null<GameSummaryPublic>;
}
