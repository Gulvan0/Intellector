package gfx.game.board.subcomponents;

import gfx.game.board.util.HexDimensions;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Point;
import haxe.ui.components.Image;
import net.shared.board.Hex;
import net.shared.board.PieceData;
import net.shared.PieceType;
import net.shared.PieceColor;

class Piece extends Image 
{
    public final pieceType:PieceType;
    public final pieceColor:PieceColor;

    private final scalingCoefficient:Float;
    public var hexDimensions:HexDimensions;
    private var aspectRatio:Float;

    private var center:Point;

    public static function pieceRelativeScale(pieceType:PieceType):Float
    {
        return switch pieceType 
        {
            case Progressor: 0.7;
            case Liberator, Defensor: 0.9;
            default: 1;
        }
    }

    public static function fromData(data:PieceData, hexDimensions:HexDimensions, ?center:Point):Piece
    {
        return new Piece(data.type, data.color, hexDimensions, center);
    }

    public function toHex():Hex
    {
        return Occupied(new PieceData(pieceType, pieceColor));
    }

    private function refreshPosition()
    {
        left = center.x - width / 2;
        top = center.y - height / 2;
    }

    public function resize(dimensions:HexDimensions, ?newCenter:Point) 
    {
        hexDimensions = dimensions;

        height = hexDimensions.height * scalingCoefficient;
        if (aspectRatio != null)
            width = height * aspectRatio;

        if (newCenter != null)
            setCenterAt(newCenter);
        else
            refreshPosition();
    }

    public function setCenterAt(position:Point) 
    {
        center = position;
        refreshPosition();
    }

    @:bind(this, UIEvent.CHANGE)
    private function onImageLoaded(?e) 
    {
        aspectRatio = originalWidth / originalHeight;
        resize(hexDimensions);
    }

    public function new(type:PieceType, color:PieceColor, hexDimensions:HexDimensions, ?center:Point) 
    {
        super();
        this.pieceType = type;
        this.pieceColor = color;
        this.scalingCoefficient = 0.85 * pieceRelativeScale(pieceType);
        this.hexDimensions = hexDimensions;

        if (center != null)
            setCenterAt(center);

        this.resource = 'assets/pieces/${type}_$pieceColor.svg';
    } 
}