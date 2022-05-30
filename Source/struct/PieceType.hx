package struct;

enum PieceType
{
    Progressor;
    Aggressor;
    Dominator;
    Liberator;
    Defensor;
    Intellector;
}

inline function letter(type:PieceType):String 
{
    return type.getName().charAt(1);
}

inline function pieceByLetter(letter:String):Null<PieceType> 
{
    return switch letter
    {
        case "r": Progressor;
        case "g": Aggressor;
        case "o": Dominator;
        case "e": Defensor;
        case "i": Liberator;
        case "n": Intellector;
        default: null;
    }
}