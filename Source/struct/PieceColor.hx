package struct;

enum PieceColor
{
    White;
    Black;
}

function opposite(color:PieceColor):PieceColor 
{
    return color == White? Black : White;    
}