package gameboard;

import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.PieceData;
import openfl.display.Shape;
import format.SVG;
import openfl.geom.Point;
import utils.AssetManager;
import openfl.display.Bitmap;
import net.shared.PieceType;
import net.shared.PieceColor;
import openfl.display.Sprite;

class Piece extends Sprite 
{
    public var type(default, null):PieceType;
    public var color(default, null):PieceColor;
    
    public static function fromData(data:PieceData, hexSideLength:Float):Piece
    {
        return new Piece(data.type, data.color, hexSideLength);
    }

    public function toHex():Hex
    {
        return Occupied(new PieceData(type, color));
    }

    public function reposition(location:HexCoords, board:Board) 
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

        var scale:Float = (Hexagon.sideToHeight(hexSideLength) * 0.85 / svg.data.height) * AssetManager.pieceRelativeScale(type);

        var targetWidth:Int = Math.round(svg.data.width * scale);
        var targetHeight:Int = Math.round(svg.data.height * scale);
        
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