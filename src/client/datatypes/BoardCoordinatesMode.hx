package client.datatypes;

enum abstract BoardCoordinatesMode(String) from String to String
{
    var ALL = "all";
    var FILES_ONLY = "files_only";
    var NONE = "none";
}
