package;

import Figure.FigureColor;

class SpectatorsField extends Field
{

    public function new(serializedPosition:String, watchedSide:FigureColor) 
    {
        super();
        hexes = Factory.produceHexes(watchedSide == White, this);
        disposeLetters();
        figures = Factory.produceFiguresFromSerialized(serializedPosition, watchedSide, this);
    }
}