package net.models.player;

import net.models.common.UserRefWithNickname;

class PlayerSearchEntry
{
	public var player:UserRefWithNickname;
	public var status:UserStatus;
	@:default(null) public var main_role:Null<UserRole>;
	public var relation:PlayerRelation;
	@:default(null) public var main_rating:Null<PlayerMainRating>;
}
