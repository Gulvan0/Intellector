package struct;

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

inline function plain(color:PieceColor):String 
{
    return color == White? "white" : "black";    
}