package net.rest.models.challenge.response;

import net.rest.models.challenge.submodels.ChallengeCreateResult;
import net.rest.models.game.response.GamePublic;
import lib.json.IJsonSerializableMacro;

class ChallengeCreateResponse implements IJsonSerializableMacro
{
	public var result:ChallengeCreateResult;
	@:default(null) public var challenge:Null<ChallengePublic>;
	@:default(null) public var callee_online:Null<Bool>;
	@:default(null) public var game:Null<GamePublic>;
}
