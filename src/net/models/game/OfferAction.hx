package net.models.game;

enum abstract OfferAction(String) from String to String
{
	var CREATE = "create";
	var CANCEL = "cancel";
	var ACCEPT = "accept";
	var DECLINE = "decline";
}
