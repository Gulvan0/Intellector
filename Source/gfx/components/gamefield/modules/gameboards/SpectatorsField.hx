package gfx.components.gamefield.modules.gameboards;

import gfx.components.gamefield.subsystems.Factory;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.MouseEvent;
import struct.PieceColor;

class SpectatorsField extends Field
{
    private override function onPress(e) 
    {
        rmbSelectionBackToNormal();
    }

    private override function onMove(e:MouseEvent)
    {
        //pass
    }

    public function new(watchedSide:PieceColor) 
    {
        super();
        orientationColor = watchedSide;
        
        var normalOrientation = watchedSide == White;
        hexes = Factory.produceHexes(this, normalOrientation);
        disposeLetters();
        figures = Factory.produceFiguresFromDefault(normalOrientation, this);
    }
}