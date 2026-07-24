package net.models.common;

enum abstract PieceKind(String) from String to String
{
	var PROGRESSOR = "progressor";
	var AGGRESSOR = "aggressor";
	var DEFENSOR = "defensor";
	var LIBERATOR = "liberator";
	var DOMINATOR = "dominator";
	var INTELLECTOR = "intellector";
}
