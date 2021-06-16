package gameboards;

import struct.PieceColor;

class SpectatorsField extends Field
{
    private var normalOrientation:Bool;

    private override function isOrientationNormal(?movingFigure:PieceColor) 
    {
        if (movingFigure == null)
            return normalOrientation;
        else if (normalOrientation)
            return movingFigure == White;
        else
            return movingFigure == Black;
    }

    private override function onPress(e) 
    {
        rmbSelectionBackToNormal();
    }

    public function new(serializedPosition:String, watchedSide:PieceColor) 
    {
        super();
        normalOrientation = watchedSide == White;
        hexes = Factory.produceHexes(normalOrientation, this);
        disposeLetters();
        figures = Factory.produceFiguresFromSerialized(serializedPosition, watchedSide, this);
    }
}