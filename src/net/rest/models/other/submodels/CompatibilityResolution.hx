package net.rest.models.other.submodels;

enum abstract CompatibilityResolution(String) from String to String
{
    var COMPATIBLE = "compatible";
    var OUTDATED_CLIENT = "outdated_client";
    var OUTDATED_SERVER = "outdated_server";
}
