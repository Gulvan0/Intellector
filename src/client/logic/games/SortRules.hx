package client.logic.games;

import client.datatypes.games.ResultColumn;
import client.datatypes.games.SortLevel;

/** How the result table's sort levels change; every rule returns a new list **/
class SortRules
{
    public static inline final MAX_LEVELS:Int = 3;

    public static function defaultLevels():Array<SortLevel>
    {
        return [new SortLevel(ID, true)];
    }

    /** A header click: sorts by `column` alone, ascending; flips it if it already is the only level **/
    public static function byHeader(levels:Array<SortLevel>, column:ResultColumn):Array<SortLevel>
    {
        if (levels.length == 1 && levels[0].column == column)
            return [new SortLevel(column, !levels[0].descending)];
        return [new SortLevel(column, false)];
    }

    public static function flip(levels:Array<SortLevel>, index:Int):Array<SortLevel>
    {
        return [for (i in 0...levels.length) i == index ? new SortLevel(levels[i].column, !levels[i].descending) : levels[i]];
    }

    /** Removing the last level restores the default **/
    public static function remove(levels:Array<SortLevel>, index:Int):Array<SortLevel>
    {
        var remaining:Array<SortLevel> = [for (i in 0...levels.length) if (i != index) levels[i]];
        return remaining.length > 0 ? remaining : defaultLevels();
    }

    /** Appends `column` as the least significant level, ascending **/
    public static function add(levels:Array<SortLevel>, column:ResultColumn):Array<SortLevel>
    {
        if (levels.length >= MAX_LEVELS || levelOf(levels, column) != null)
            return levels;
        return levels.concat([new SortLevel(column, false)]);
    }

    /** The columns a new level may sort by, of `visible` **/
    public static function addable(levels:Array<SortLevel>, visible:Array<ResultColumn>):Array<ResultColumn>
    {
        if (levels.length >= MAX_LEVELS)
            return [];
        return ResultColumns.ordered(visible).filter(column -> ResultColumns.isSortable(column) && levelOf(levels, column) == null);
    }

    /** The 0-based index of the level sorting by `column`, null if none **/
    public static function levelOf(levels:Array<SortLevel>, column:ResultColumn):Null<Int>
    {
        for (i in 0...levels.length)
            if (levels[i].column == column)
                return i;
        return null;
    }
}
