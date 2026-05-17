package net.models.challenge;

import net.models.challenge.ChallengeCreateResult;
import net.models.game.GameSummaryPublic;
import net.models.challenge.ChallengePublic;
import lib.json.IJsonUnserializableMacro;

class ChallengeCreateResponse implements IJsonUnserializableMacro
{
	public var result:ChallengeCreateResult;
	@:default(null) public var challenge:Null<ChallengePublic>;
	@:default(null) public var callee_online:Null<Bool>;
	@:default(null) public var game:Null<GameSummaryPublic>;
}
