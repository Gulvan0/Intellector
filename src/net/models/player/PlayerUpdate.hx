package net.models.player;

import net.models.player.UserRole;
import jsonmodel.IJsonSerializableMacro;

@:structInit
class PlayerUpdate implements IJsonSerializableMacro
{
	public var nickname:Null<String> = null;
	public var preferred_role:Null<UserRole> = null;
}
