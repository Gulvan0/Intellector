package net.models.common;

enum abstract TimeControlKind(String) from String to String
{
	var HYPERBULLET = "hyperbullet";
	var BULLET = "bullet";
	var BLITZ = "blitz";
	var RAPID = "rapid";
	var CLASSIC = "classic";
	var CORRESPONDENCE = "correspondence";
}
