package gameboard.components.graphics;

import haxe.ui.components.Canvas;

class HexagonDotCanvas extends Canvas
{
    public function new(boxWidth:Float, boxHeight:Float, hexSideLength:Float) 
    {
        super();
        this.width = boxWidth;
        this.height = boxHeight;

        componentGraphics.fillStyle(0x333333);
        componentGraphics.circle(boxWidth / 2, boxHeight / 2, 0.2 * hexSideLength);
    }
}