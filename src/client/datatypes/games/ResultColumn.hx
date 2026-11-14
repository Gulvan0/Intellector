package client.datatypes.games;

/** A column of the game database's result table, by its id shared with the server **/
enum abstract ResultColumn(String) from String to String
{
    var ID = "id";
    var LINK = "link";
    var WHITE = "white";
    var BLACK = "black";
    var WHITE_ELO = "white_elo";
    var BLACK_ELO = "black_elo";
    var STARTED_AT = "started_at";
    var ENDED_AT = "ended_at";
    var DURATION = "duration";
    var TIME_CONTROL = "time_control";
    var START_TIME = "start_time";
    var BONUS_TIME = "bonus_time";
    var RATED = "rated";
    var STARTING_POSITION = "starting_position";
    var RESULT = "result";
    var OUTCOME = "outcome";
    var OPENING = "opening";
    var MOVE_COUNT = "move_count";
    var TIME_LEFT_WHITE = "time_left_white";
    var TIME_LEFT_BLACK = "time_left_black";
}
