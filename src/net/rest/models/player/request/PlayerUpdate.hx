package net.rest.models.player.request;

import net.rest.models.player.submodels.UserRole;
import lib.json.IJsonSerializableMacro;

@:structInit
class PlayerUpdate implements IJsonSerializableMacro
{
	public var nickname:Null<String> = null;
	public var preferred_role:Null<UserRole> = null;
}
