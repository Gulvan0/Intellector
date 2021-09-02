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