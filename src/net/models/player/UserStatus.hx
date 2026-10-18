package net.models.player;

enum abstract UserStatus(String) from String to String
{
	var PLAYING = "playing";
	var ONLINE = "online";
	var AWAY = "away";
	var OFFLINE = "offline";
}
