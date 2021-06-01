package analysis;

import Figure.FigureType;
import Figure.FigureColor;

enum Hex 
{
    Empty;
    Figure(color:FigureColor, type:FigureType);
}

function color(h:Hex) 
{
    return switch h {
        case Empty: null;
        case Figure(c, t): c;
    }
}

function type(h:Hex) 
{
    return switch h {
        case Empty: null;
        case Figure(c, t): t;
    }
}