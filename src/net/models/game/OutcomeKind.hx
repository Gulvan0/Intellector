package net.models.game;

enum abstract OutcomeKind(String) from String to String
{
	var FATUM = "fatum";
	var BREAKTHROUGH = "breakthrough";
	var TIMEOUT = "timeout";
	var RESIGN = "resign";
	var ABANDON = "abandon";
	var CHEATING_ABORT = "cheating_abort";
	var DRAW_AGREEMENT = "draw_agreement";
	var REPETITION = "repetition";
	var NO_PROGRESS = "no_progress";
	var ABORT = "abort";
}
