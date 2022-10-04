package net.shared;

enum PieceColor
{
    White;
    Black;
}

inline function opposite(color:PieceColor):PieceColor 
{
    return color == White? Black : White;    
}

inline function letter(color:PieceColor):String 
{
    return color == White? "w" : "b";    
}

inline function colorByLetter(letter:String):Null<PieceColor> 
{
    return switch letter
    {
        case "w": White;
        case "b": Black;
        default: null;
    }
}