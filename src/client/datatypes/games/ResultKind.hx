package client.datatypes.games;

/** By its name in the formula format **/
enum abstract ResultKind(String) from String to String
{
    var ONGOING = "ongoing";
    var WHITE_WON = "white_won";
    var BLACK_WON = "black_won";
    var DRAW = "draw";
}
