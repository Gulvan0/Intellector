package client.logic.games;

import client.datatypes.games.ResultColumn;

/** The result table's column roster **/
class ResultColumns
{
    /** In the table's order **/
    public static final ALL:Array<ResultColumn> = [
        ID,
        LINK,
        WHITE,
        BLACK,
        WHITE_ELO,
        BLACK_ELO,
        STARTED_AT,
        ENDED_AT,
        DURATION,
        TIME_CONTROL,
        START_TIME,
        BONUS_TIME,
        RATED,
        STARTING_POSITION,
        RESULT,
        OUTCOME,
        OPENING,
        MOVE_COUNT,
        TIME_LEFT_WHITE,
        TIME_LEFT_BLACK
    ];

    public static final DEFAULT_VISIBLE:Array<ResultColumn> = [ID, WHITE, BLACK, STARTED_AT, DURATION, TIME_CONTROL, START_TIME, BONUS_TIME, RATED, RESULT, OUTCOME];

    /** The link duplicates the id **/
    public static function isSortable(column:ResultColumn):Bool
    {
        return column != LINK;
    }

    /** `columns`, in the table's order **/
    public static function ordered(columns:Array<ResultColumn>):Array<ResultColumn>
    {
        return ALL.filter(column -> columns.contains(column));
    }

    public static function nameKey(column:ResultColumn):String
    {
        return 'intellector.games.column.$column';
    }
}
