package;

import Figure.FigureColor;

class SpectatorsField extends Field
{

    public function new(serializedPosition:String, watchedSide:FigureColor) 
    {
        super();
        figures = Factory.produceFiguresFromSerialized(serializedPosition, watchedSide, this);
    }
}