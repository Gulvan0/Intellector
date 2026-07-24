package net.models.player;

enum abstract UserStatus(String) from String to String
{
	var ONLINE = "online";
	var AWAY = "away";
	var OFFLINE = "offline";
}
