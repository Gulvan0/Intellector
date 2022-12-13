package gameboard.lightweight;

import format.SVG;
import net.shared.PieceType;
import net.shared.PieceColor;
import utils.AssetManager;
import openfl.display.Shape;

class LightPiece extends Shape
{
    public function new(type:PieceType, color:PieceColor, hexSideLength:Float)
    {
        super();

        var svg:SVG = AssetManager.pieces[type][color];

        var scale:Float = (Hexagon.sideToHeight(hexSideLength) * 0.85 / svg.data.height) * AssetManager.pieceRelativeScale(type);

        var targetWidth:Int = Math.round(svg.data.width * scale);
        var targetHeight:Int = Math.round(svg.data.height * scale);
        
        svg.render(graphics, -targetWidth/2, -targetHeight/2, targetWidth, targetHeight);
    }
}