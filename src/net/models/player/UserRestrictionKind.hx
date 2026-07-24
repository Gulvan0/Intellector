package net.models.player;

enum abstract UserRestrictionKind(String) from String to String
{
	var RATED_GAMES = "rated_games";
	var SET_AVATAR = "set_avatar";
	var CHAT = "chat";
}
