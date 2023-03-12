package gfx.live.board.subcomponents.canvas;

import haxe.ui.components.Canvas;

class HexagonCircleCanvas extends Canvas
{
    public function new(boxWidth:Float, boxHeight:Float, hexSideLength:Float) 
    {
        super();
        this.width = boxWidth;
        this.height = boxHeight;

        componentGraphics.fillStyle(null, 0);
        componentGraphics.strokeStyle(0x333333, hexSideLength / 10);
        componentGraphics.circle(boxWidth / 2, boxHeight / 2, 0.8 * hexSideLength);
    }
}