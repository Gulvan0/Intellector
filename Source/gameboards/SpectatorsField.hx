package gameboards;

import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import struct.PieceColor;

class SpectatorsField extends Field
{
    private var normalOrientation:Bool;
    private var stageRef:Stage;

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

    public function new(watchedSide:PieceColor) 
    {
        super();
        normalOrientation = watchedSide == White;
        hexes = Factory.produceHexes(this, normalOrientation);
        disposeLetters();
        figures = Factory.produceFiguresFromDefault(normalOrientation, this);
    
        addEventListener(Event.ADDED_TO_STAGE, init);
    }

    private function init(e) 
    {
        removeEventListener(Event.ADDED_TO_STAGE, init);

        stageRef = stage;
        stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onPress);
        addEventListener(Event.REMOVED_FROM_STAGE, terminate);
    }

    private function terminate(e) 
    {
        removeEventListener(Event.REMOVED_FROM_STAGE, terminate);
        stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, onPress);
    }
}