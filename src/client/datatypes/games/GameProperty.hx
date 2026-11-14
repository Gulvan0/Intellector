package client.datatypes.games;

/** A game property a formula condition tests, by its name in the formula format **/
enum abstract GameProperty(String) from String to String
{
    var STARTED_AT = "started_at";
    var ENDED_AT = "ended_at";
    var INITIAL_TIME = "initial_time";
    var BONUS_TIME = "bonus_time";
    var DURATION = "duration";
    var TIME_LEFT = "time_left";
    var MOVE_CNT = "move_cnt";
    var ELO = "elo";
    var PLAYER = "player";
    var TIME_CONTROL_KIND = "time_control_kind";
    var RATED = "rated";
    var OUTCOME = "outcome";
    var STARTING_POSITION = "starting_position";
    var OPENING = "opening";
    var ELO_PROVISIONAL = "elo_provisional";
    var WINNER = "winner";
    var RESULT = "result";
}
