package net.models.challenge;

enum abstract ChallengeKind(String) from String to String
{
	var PUBLIC = "public";
	var LINK_ONLY = "link_only";
	var DIRECT = "direct";
}
