package net.models.other;

import jsonmodel.IJsonUnserializableMacro;
import net.models.common.UserRefWithNickname;

class SubscriberListChannelStateRefresh implements IJsonUnserializableMacro
{
	public var subscribers:Array<UserRefWithNickname>;
	public var unauthenticated_subs_count:Int;
}
