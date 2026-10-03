package client.datatypes;

/**
    How a hex annotation is drawn: a ring around the hex, or a fill of the hex.
**/
enum abstract AnnotationHexStyle(String) from String to String
{
    var CIRCLE = "circle";
    var TINT = "tint";
}
