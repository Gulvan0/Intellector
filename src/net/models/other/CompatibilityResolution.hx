package net.models.other;

enum abstract CompatibilityResolution(String) from String to String
{
	var COMPATIBLE = "compatible";
	var OUTDATED_CLIENT = "outdated_client";
	var OUTDATED_SERVER = "outdated_server";
}
