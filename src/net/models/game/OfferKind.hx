package net.models.game;

enum abstract OfferKind(String) from String to String
{
	var DRAW = "draw";
	var TAKEBACK = "takeback";
}
