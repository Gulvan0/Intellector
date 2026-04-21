package net.models.game;

enum abstract EventKind(String) from String to String
{
	var PLY = "ply";
	var CHAT_MESSAGE = "chat_message";
	var OFFER = "offer";
	var TIME_ADDED = "time_added";
	var ROLLBACK = "rollback";
}
