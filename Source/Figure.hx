package;

import struct.PieceColor;
import struct.PieceType;
import struct.Hex;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;

class Figure extends Sprite 
{
    public var hex:Hex;
    public var type(get, never):PieceType;
    public var color(get, never):PieceColor;

    public static function fromHex(h:Hex):Figure
    {
        return new Figure(h.type, h.color);
    }

    public function new(type:PieceType, color:PieceColor)
    {
        super();
        this.hex = Hex.occupied(type, color);
        draw();
    }

    public function get_type():PieceType
    {
        return hex.type;
    }

    public function get_color():PieceColor
    {
        return hex.color;
    }

    private function draw() 
    {
        var bitmap = new Bitmap(AssetManager.pieceBitmaps[type][color]);
        bitmap.x = -bitmap.width / 2;
        bitmap.y = -bitmap.height / 2;
        addChild(bitmap);    
    }
}