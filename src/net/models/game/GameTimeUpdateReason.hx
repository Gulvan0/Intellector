package net.models.game;

enum abstract GameTimeUpdateReason(String) from String to String
{
	var INIT = "init";
	var PLY = "ply";
	var ROLLBACK = "rollback";
	var TIME_ADDED = "time_added";
	var GAME_ENDED = "game_ended";
}
