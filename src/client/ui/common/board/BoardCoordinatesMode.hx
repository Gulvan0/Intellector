package client.ui.common.board;

/**
    How board coordinate labels are displayed on a `BoardSurface`. Mirrors the values of
    `Preferences.boardCoordinates`, kept as its own enum here so `BoardSurface`'s API stays typed
    rather than stringly-typed - the mapping from the raw preference string happens once, at
    whichever call site reads the preference.
**/
enum BoardCoordinatesMode
{
    /**
        Every hex shows its own row number, and file letters are drawn in a row below the board.
    **/
    All;

    /**
        Only file letters are drawn, in a row below the board.
    **/
    FilesOnly;

    /**
        No coordinate labels at all.
    **/
    None;
}

class BoardCoordinatesModeExtension
{
    public static function fromPreferenceValue(value:String):BoardCoordinatesMode
    {
        return switch value
        {
            case "all": All;
            case "files_only": FilesOnly;
            case "none": None;
            default: throw 'Unknown board coordinates preference value: $value';
        }
    }
}
