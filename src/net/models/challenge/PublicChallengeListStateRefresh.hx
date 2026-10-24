package net.models.challenge;

import jsonmodel.IJsonUnserializableMacro;
import net.models.challenge.ChallengePublic;

/** The newest public challenges, a head window of the list: the further ones come from `GET_PUBLIC_CHALLENGES` **/
class PublicChallengeListStateRefresh implements IJsonUnserializableMacro
{
	public var challenges:Array<ChallengePublic>;
	public var total:Int;
	public var has_more:Bool;
}
