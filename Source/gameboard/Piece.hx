package gameboard;

import struct.IntPoint;
import openfl.display.Shape;
import format.SVG;
import openfl.geom.Point;
import utils.AssetManager;
import openfl.display.Bitmap;
import struct.Hex;
import struct.PieceType;
import struct.PieceColor;
import openfl.display.Sprite;

class Piece extends Sprite 
{
    public var type(default, null):PieceType;
    public var color(default, null):PieceColor;
    
    public static function fromHex(hex:Hex, hexSideLength:Float):Piece
    {
        return new Piece(hex.type, hex.color, hexSideLength);
    }

    public function reposition(location:IntPoint, board:Board) 
    {
        repositionExact(board.hexCoords(location));
    }

    public function repositionExact(pos:Point) 
    {
        x = pos.x;
        y = pos.y;    
    }

    public function redraw(hexSideLength:Float) 
    {
        graphics.clear();
        var svg:SVG = AssetManager.pieces[type][color];

        var scale = Hexagon.sideToHeight(hexSideLength) * 0.85 / svg.data.height;
        if (type == Progressor)
            scale *= 0.7;
        else if (type == Liberator || type == Defensor)
            scale *= 0.9;

        var targetWidth = Math.round(svg.data.width * scale);
        var targetHeight = Math.round(svg.data.height * scale);
        
        svg.render(graphics, -targetWidth/2, -targetHeight/2, targetWidth, targetHeight);
    }

    public function new(type:PieceType, color:PieceColor, hexSideLength:Float) 
    {
        super();
        this.type = type;
        this.color = color;

        redraw(hexSideLength);
    } 
}