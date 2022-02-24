package gameboard;

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

    public function getFieldHeight():Float
    {
        return Hexagon.sideToHeight(hexSideLength) * 7;
    }

    public function setOrientation(val:PieceColor):PieceColor 
    {
        if (val != orientationColor)
        {
            orientationColor = val;

            for (s in 0...pieces.length)
            {
                var piece = pieces[s];
                if (piece != null)
                {
                    var coords = hexCoords(IntPoint.fromScalar(s));
                    piece.x = coords.x;
                    piece.y = coords.y;
                }
            }

            if (!Lambda.empty(letters))
                swapLetters();
        }

        return orientationColor;    
    }

    public function setSituation(val:Situation)
    {
        for (piece in pieces)
            removeChild(piece);
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
                removeChild(getPiece(oldIntellectorPosition));
                pieces[oldIntellectorPosition.toScalar()] = null;
                shownSituation.set(oldIntellectorPosition, Hex.empty());
            }
        }
        var formerPiece = getPiece(location);
        if (formerPiece != null)
            removeChild(formerPiece);
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
                removeChild(getPiece(transform.coords));
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
    
    private function posToIndexes(x:Float, y:Float):Null<IntPoint>
    {
        var closest:Null<IntPoint> = null;
        var distanceSqr:Float = hexSideLength * hexSideLength;
        for (j in 0...7)
            for (i in 0...9)
            {
                var loc = new IntPoint(i, j);
                if (!hexExists(loc))
                    continue;
                var coords:Point = hexCoords(loc);
                var currDistSqr = (coords.x - x) * (coords.x - x) + (coords.y - y) * (coords.y - y);
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

        for (s in 0...59)
        {
            var p:IntPoint = IntPoint.fromScalar(s);
            var hexagon:Hexagon = new Hexagon(hexSideLength, p.i, p.j, displayRowNumbers);
            var coords = hexCoords(p);
            hexagon.x = coords.x;
            hexagon.y = coords.y;
            addChild(hexagon);
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
            var piece:Piece = Piece.fromHex(hex);
            var coords = hexCoords(location);
            piece.rescale(hexSideLength);
            piece.x = coords.x;
            piece.y = coords.y;
            addChild(piece);
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
            var letter = createLetter(Notation.getColumn(i));
            letter.x = bottomHexCoords.x - letter.textWidth / 2 - 5;
            letter.y = bottomHexCoords.y + Hexagon.sideToHeight(hexSideLength) / 2;
            letters.push(letter);
            addChild(letter); 
        }
    }

    private function createLetter(letter:String):TextField 
    {
        var tf = new TextField();
        tf.text = letter;
        tf.setTextFormat(new TextFormat(null, 28, Colors.border, true));
        tf.selectable = false;
        return tf;
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, hexSideLength:Float = 40, suppressMarkup:Bool = false) 
    {
        super(-hexSideLength, -Hexagon.sideToHeight(hexSideLength) / 2);
        this.hexSideLength = hexSideLength;
        this.orientationColor = orientationColor;
        this.shownSituation = situation.copy();

        produceHexagons(!suppressMarkup && Preferences.instance.markup == Over);
        producePieces();
        if (!suppressMarkup && Preferences.instance.markup != None)
            disposeLetters();
    }

}