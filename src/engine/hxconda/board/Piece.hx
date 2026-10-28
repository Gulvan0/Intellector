package engine.hxconda.board;

/**
    Piece codes of the Anaconda notation. Each white piece has an even code, its black counterpart has the next odd one.
**/
enum abstract Piece(Int) to Int
{
    var WhiteProgressor = 0;
    var BlackProgressor = 1;
    var WhiteDominator = 2;
    var BlackDominator = 3;
    var WhiteLiberator = 4;
    var BlackLiberator = 5;
    var WhiteAggressor = 6;
    var BlackAggressor = 7;
    var WhiteDefensor = 8;
    var BlackDefensor = 9;
    var WhiteIntellector = 10;
    var BlackIntellector = 11;
    var Empty = 12;

    /** Number of codes, `Empty` included **/
    public static inline final COUNT:Int = 13;

    public static function fromLetter(letter:String):Null<Piece>
    {
        return switch letter {
            case "p": WhiteProgressor;
            case "m": WhiteDominator;
            case "l": WhiteLiberator;
            case "a": WhiteAggressor;
            case "d": WhiteDefensor;
            case "i": WhiteIntellector;
            case "P": BlackProgressor;
            case "M": BlackDominator;
            case "L": BlackLiberator;
            case "A": BlackAggressor;
            case "D": BlackDefensor;
            case "I": BlackIntellector;
            case "e": Empty;
            default: null;
        }
    }

    /** Undefined for `Empty` **/
    public inline function color():PlayerColor
    {
        return cast (this & 1);
    }

    /** The same kind of piece of the opposite color **/
    public inline function counterpart():Piece
    {
        return cast (this ^ 1);
    }

    /** The same kind of piece of `color`; `this` has to be a white piece **/
    public inline function ofColor(color:PlayerColor):Piece
    {
        return cast (this | color);
    }

    public inline function isIntellector():Bool
    {
        return abstract == WhiteIntellector || abstract == BlackIntellector;
    }
}
