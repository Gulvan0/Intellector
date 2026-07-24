package net.models.challenge;

import lib.json.IJsonUnserializableMacro;
import net.models.challenge.ChallengePublic;

class ChallengeListStateRefresh implements IJsonUnserializableMacro
{
	public var challenges:Array<ChallengePublic>;
}
