package net.models.player;

import net.models.common.UserRefWithNickname;

class PlayerCard
{
	public var player:UserRefWithNickname;
	public var status:UserStatus;
	@:default(null) public var main_rating:Null<PlayerMainRating>;
}
