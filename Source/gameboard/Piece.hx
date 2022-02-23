package gameboard;

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
    
    public static function fromHex(hex:Hex):Piece
    {
        return new Piece(hex.type, hex.color);
    }

    public function dispose(pos:Point) 
    {
        x = pos.x;
        y = pos.y;    
    }

    public function rescale(hexSideLength:Float) 
    {
        var scale = Hexagon.sideToHeight(hexSideLength) * 0.85 / height;
        if (type == Progressor)
            scale *= 0.7;
        else if (type == Liberator || type == Defensor)
            scale *= 0.9;
        scaleX = scale;
        scaleY = scale;
    }

    public function new(type:PieceType, color:PieceColor) 
    {
        super();
        this.type = type;
        this.color = color;

        var bitmap = new Bitmap(AssetManager.pieceBitmaps[type][color]);
        bitmap.x = -bitmap.width / 2;
        bitmap.y = -bitmap.height / 2;
        addChild(bitmap);   
    } 
}