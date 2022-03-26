package gameboard;

import utils.MathUtils;
import openfl.display.Sprite;
import gfx.utils.Colors;
import utils.Notation;
import openfl.text.TextFormat;
import openfl.text.TextField;
import openfl.geom.Point;
import struct.ReversiblePly;
import struct.Hex;
import struct.Situation;
import struct.IntPoint;
import struct.PieceColor;
import gfx.components.OffsettedSprite;

/**
    A simplest board with a very basic functionality
**/
class Board extends OffsettedSprite
{
    //?Maybe a setter will be added later for dynamic resizing
    public var hexSideLength(default, null):Float;

    public var hexagons:Array<Hexagon>;
    public var pieces:Array<Null<Piece>>;

    public var orientationColor(default, null):PieceColor;
    public var shownSituation(default, null):Situation;

    private var letters:Array<TextField> = [];

    private var hexagonLayer:Sprite;
    private var pieceLayer:Sprite;

    public function getFieldHeight():Float
    {
        return Hexagon.sideToHeight(hexSideLength) * 7;
    }

    public function revertOrientation()
    {
        setOrientation(opposite(orientationColor));
    }

    public function setOrientation(val:PieceColor) 
    {
        if (val != orientationColor)
        {
            orientationColor = val;

            for (s in 0...IntPoint.hexCount)
            {
                var coords = hexCoords(IntPoint.fromScalar(s));

                var hexagon = hexagons[s];
                var piece = pieces[s];

                hexagon.x = coords.x;
                hexagon.y = coords.y;

                if (piece != null)
                    piece.dispose(coords);
            }

            if (!Lambda.empty(letters))
                swapLetters();
        } 
    }

    public function setSituation(val:Situation)
    {
        for (piece in pieces)
            pieceLayer.removeChild(piece);
        pieces = [];
        shownSituation = val;
        producePieces();
    }

    public function clearPieces()
    {
        setSituation(Situation.empty());
    }

    public function setHexDirectly(location:IntPoint, hex:Hex)
    {
        if (hex.type == Intellector)
        {
            var oldIntellectorPosition:Null<IntPoint> = shownSituation.intellectorPos[hex.color];
            if (oldIntellectorPosition != null)
            {
                pieceLayer.removeChild(getPiece(oldIntellectorPosition));
                pieces[oldIntellectorPosition.toScalar()] = null;
                shownSituation.set(oldIntellectorPosition, Hex.empty());
            }
        }
        var formerPiece = getPiece(location);
        if (formerPiece != null)
            pieceLayer.removeChild(formerPiece);
        producePiece(location, hex);
        shownSituation.set(location, hex.copy());
    }

    public function applyMoveTransposition(ply:ReversiblePly, backInTime:Bool = false)
    {
        for (transform in ply)
        {
            var currentHex = backInTime? transform.latter : transform.former;
            var goalHex = backInTime? transform.former : transform.latter;

            if (!currentHex.isEmpty())
                pieceLayer.removeChild(getPiece(transform.coords));
            producePiece(transform.coords, goalHex);
            shownSituation.set(transform.coords, goalHex, false);
        }
    }

    public function getHex(coords:Null<IntPoint>):Null<Hexagon>
    {
        if (hexExists(coords))
            return hexagons[coords.toScalar()];
        else
            return null;
    }
    
    public function getPiece(coords:Null<IntPoint>):Null<Piece>
    {
        if (hexExists(coords))
            return pieces[coords.toScalar()];
        else
            return null;
    }

    public static function hexExists(p:Null<IntPoint>):Bool
    {
        if (p != null)
            return p.i >= 0 && p.i < 9 && p.j >= 0 && p.j < 7 - p.i % 2;
        else
            return null;
    }
    
    private function posToIndexes(stageX:Float, stageY:Float):Null<IntPoint>
    {
        var localEventCoords:Point = globalToLocal(new Point(stageX, stageY));
        var closest:Null<IntPoint> = null;
        var distanceSqr:Float = hexSideLength * hexSideLength;

        for (j in 0...7)
            for (i in 0...9)
            {
                var loc = new IntPoint(i, j);
                if (!hexExists(loc))
                    continue;
                var coords:Point = hexCoords(loc);
                var currDistSqr = (coords.x - localEventCoords.x) * (coords.x - localEventCoords.x) + (coords.y - localEventCoords.y) * (coords.y - localEventCoords.y);
                if (distanceSqr > currDistSqr)
                {
                    closest = loc;
                    distanceSqr = currDistSqr;
                }
            }

        return closest;
    }

    public function hexCoords(location:IntPoint):Point
    {
        return absHexCoords(location.i, location.j, orientationColor == White);
    }

    private function absHexCoords(i:Int, j:Int, isOrientationNormal:Bool):Point
    {
        if (!isOrientationNormal)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }

        var hexWidth:Float = Hexagon.sideToWidth(hexSideLength);
        var hexHeight:Float = Hexagon.sideToHeight(hexSideLength);

        var p:Point = new Point(0, 0);
        p.x = 3 * hexSideLength * i / 2;
        p.y = hexHeight * j;

        if (i % 2 == 1)
            p.y += hexHeight / 2;

        return p;
    }

    private function produceHexagons(displayRowNumbers:Bool)
    {
        hexagons = [];

        for (s in 0...IntPoint.hexCount)
        {
            var p:IntPoint = IntPoint.fromScalar(s);
            var hexagon:Hexagon = new Hexagon(hexSideLength, p.i, p.j, displayRowNumbers);
            var coords = hexCoords(p);
            hexagon.x = coords.x;
            hexagon.y = coords.y;
            hexagonLayer.addChild(hexagon);
            hexagons.push(hexagon);
        }
    }

    private function producePieces()
    {
        pieces = [];

        for (s in 0...59)
        {
            var p = IntPoint.fromScalar(s);
            producePiece(p, shownSituation.get(p));
        }
    }

    private function producePiece(location:IntPoint, hex:Hex)
    {
        var scalarCoord = location.toScalar();
        if (hex.isEmpty())
            pieces[scalarCoord] = null;
        else
        {
            var piece:Piece = Piece.fromHex(hex, hexSideLength);
            piece.dispose(hexCoords(location));
            pieceLayer.addChild(piece);
            pieces[scalarCoord] = piece;
        }
    }

    private function swapLetters() 
    {
        for (i in 0...4)
        {
            var t = letters[i].text;
            letters[i].text = letters[8-i].text;
            letters[8-i].text = t;
        }
    }

    private function disposeLetters() 
    {
        for (i in 0...9)
        {
            var bottomHexCoords:Point = absHexCoords(i, 6 - i % 2, true);
            var letter = createLetter(Notation.getColumn(i), hexSideLength);
            letter.x = bottomHexCoords.x - letter.textWidth / 2 - 5;
            letter.y = bottomHexCoords.y + Hexagon.sideToHeight(hexSideLength) / 2;
            letters.push(letter);
            hexagonLayer.addChild(letter); 
        }
    }

    private function createLetter(letter:String, hexSideLength:Float):TextField 
    {
        var tf = new TextField();
        tf.text = letter;
        tf.setTextFormat(new TextFormat(null, MathUtils.intScaleLike(28, 40, hexSideLength), Colors.border, true));
        tf.selectable = false;
        return tf;
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, hexSideLength:Float = 40, suppressMarkup:Bool = false) 
    {
        super(-hexSideLength, -Hexagon.sideToHeight(hexSideLength) / 2);
        this.hexSideLength = hexSideLength;
        this.orientationColor = orientationColor;
        this.shownSituation = situation.copy();
        this.hexagonLayer = new Sprite();
        this.pieceLayer = new Sprite();

        addChild(hexagonLayer);
        addChild(pieceLayer);

        produceHexagons(!suppressMarkup && Preferences.instance.markup == Over);
        producePieces();
        if (!suppressMarkup && Preferences.instance.markup != None)
            disposeLetters();
    }

}