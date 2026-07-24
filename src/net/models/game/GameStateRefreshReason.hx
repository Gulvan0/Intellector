package net.models.game;

enum abstract GameStateRefreshReason(String) from String to String
{
	var SUB = "SUB";
	var INVALID_MOVE = "INVALID_MOVE";
}
