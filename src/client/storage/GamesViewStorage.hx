package client.storage;

import client.datatypes.games.ResultColumn;
import client.datatypes.games.SortLevel;
import client.logic.games.ResultColumns;
import client.logic.games.SortRules;
import haxefolio.HaxeFolioApp;

/** The game database's per-viewer view settings: the visible columns and the last sorting **/
class GamesViewStorage
{
    private static inline final DESCENDING_SUFFIX:String = ":desc";

    public static function readColumns():Array<ResultColumn>
    {
        var serialized:Null<String> = HaxeFolioApp.valueStorage.read(LocalStorageKey.GAMES_COLUMNS);
        if (serialized == null)
            return ResultColumns.DEFAULT_VISIBLE.copy();

        var columns:Array<ResultColumn> = ResultColumns.ALL.filter(column -> serialized.split(",").contains(column));
        return columns.length > 0 ? columns : ResultColumns.DEFAULT_VISIBLE.copy();
    }

    public static function saveColumns(columns:Array<ResultColumn>):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.GAMES_COLUMNS, columns.join(","));
    }

    public static function readSort():Array<SortLevel>
    {
        var serialized:Null<String> = HaxeFolioApp.valueStorage.read(LocalStorageKey.GAMES_SORT);
        if (serialized == null)
            return SortRules.defaultLevels();

        var levels:Array<SortLevel> = [];
        for (item in serialized.split(","))
        {
            var descending:Bool = StringTools.endsWith(item, DESCENDING_SUFFIX);
            var column:ResultColumn = descending ? item.substr(0, item.length - DESCENDING_SUFFIX.length) : item;
            if (ResultColumns.ALL.contains(column) && ResultColumns.isSortable(column) && SortRules.levelOf(levels, column) == null)
                levels.push(new SortLevel(column, descending));
        }
        return levels.length > 0 && levels.length <= SortRules.MAX_LEVELS ? levels : SortRules.defaultLevels();
    }

    /** `<column>` or `<column>:desc` per level **/
    public static function saveSort(levels:Array<SortLevel>):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.GAMES_SORT, levels.map(level -> level.descending ? level.column + DESCENDING_SUFFIX : (level.column : String)).join(","));
    }
}
