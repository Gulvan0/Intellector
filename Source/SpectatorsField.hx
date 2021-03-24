package;

import Figure.FigureType;
import openfl.Assets;
import openfl.events.Event;
import Figure.FigureColor;
import openfl.events.MouseEvent;
import openfl.geom.Point;
import openfl.display.Sprite;

class SpectatorsField extends Field
{

    public function new(serializedPosition:String) 
    {
        super();
        figures = Factory.produceFiguresFromSerialized(serializedPosition, this);
    }
}