package;

import Figure.FigureColor;

class SpectatorsField extends Field
{
    private var normalOrientation:Bool;

    private override function isOrientationNormal(?movingFigure:FigureColor) 
    {
        if (movingFigure == null)
            return normalOrientation;
        else if (normalOrientation)
            return movingFigure == White;
        else
            return movingFigure == Black;
    }

    public function new(serializedPosition:String, watchedSide:FigureColor) 
    {
        super();
        normalOrientation = watchedSide == White;
        hexes = Factory.produceHexes(normalOrientation, this);
        disposeLetters();
        figures = Factory.produceFiguresFromSerialized(serializedPosition, watchedSide, this);
    }
}