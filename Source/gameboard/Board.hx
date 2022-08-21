package gameboard;

import Preferences.Markup;
import haxe.ui.components.Label;
import struct.Ply;
import utils.MathUtils;
import openfl.display.Sprite;
import gfx.utils.Colors;
import utils.Notation;
import openfl.geom.Point;
import struct.ReversiblePly;
import struct.Hex;
import struct.Situation;
import struct.IntPoint;
import struct.PieceColor;

/**
    A simplest board with a very basic functionality
**/
class Board extends Sprite
{
    public var hexSideLength(default, null):Float;
    public var lettersEnabled(default, null):Bool;

    public var hexagons:Array<Hexagon>;
    public var pieces:Array<Null<Piece>>;

    public var orientationColor(default, null):PieceColor;

    private var _shownSituation:Situation;
    public var shownSituation(get, never):Situation;

    private var letters:Array<Label> = [];

    private var hexagonLayer:Sprite;
    private var pieceLayer:Sprite;

    public function getFieldHeight():Float
    {
        return Hexagon.sideToHeight(hexSideLength) * 7;
    }

    private function get_shownSituation():Situation
    {
        return _shownSituation.copy();
    }
    
    public function resize(newHexSideLength:Float)
    {
        this.hexSideLength = newHexSideLength;
        for (s in 0...IntPoint.hexCount)
        {
            var coords = hexCoords(IntPoint.fromScalar(s));

            var hexagon = hexagons[s];
            var piece = pieces[s];

            hexagon.resize(newHexSideLength);
            hexagon.x = coords.x;
            hexagon.y = coords.y;

            if (piece != null)
            {
                piece.redraw(newHexSideLength);
                piece.repositionExact(coords);
            }
        }
        if (lettersEnabled)
        {
            removeLetters();
            drawLetters();
        }
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
                    piece.repositionExact(coords);
            }

            if (!Lambda.empty(letters))
                swapLetters();
        } 
    }

    public function setShownSituation(val:Situation)
    {
        for (piece in pieces)
            pieceLayer.removeChild(piece);
        pieces = [];
        _shownSituation = val.copy();
        producePieces();
    }

    public function clearPieces()
    {
        setShownSituation(Situation.empty());
    }

    public function setHexDirectly(location:IntPoint, hex:Hex)
    {
        if (hex.type == Intellector)
        {
            var oldIntellectorPosition:Null<IntPoint> = _shownSituation.intellectorPos[hex.color];
            if (oldIntellectorPosition != null)
            {
                pieceLayer.removeChild(getPiece(oldIntellectorPosition));
                pieces[oldIntellectorPosition.toScalar()] = null;
                _shownSituation.set(oldIntellectorPosition, Hex.empty());
            }
        }
        var formerPiece = getPiece(location);
        if (formerPiece != null)
            pieceLayer.removeChild(formerPiece);
        producePiece(location, hex);
        _shownSituation.set(location, hex.copy());
    }

    public function applyPremoveTransposition(ply:Ply) 
    {
        var departurePiece = getPiece(ply.from);
        var destinationPiece = getPiece(ply.to);

        if (ply.morphInto != null)
        {
            pieceLayer.removeChild(departurePiece);
            pieces[ply.from.toScalar()] = null;
            _shownSituation.set(ply.from, Hex.empty());

            if (destinationPiece != null)
                pieceLayer.removeChild(destinationPiece);
            producePiece(ply.to, Hex.occupied(ply.morphInto, departurePiece.color));
            _shownSituation.set(ply.to, Hex.occupied(ply.morphInto, departurePiece.color));
        }
        else
        {
            departurePiece.reposition(ply.to, this);
            pieces[ply.to.toScalar()] = departurePiece;
            _shownSituation.set(ply.to, Hex.occupied(departurePiece.type, departurePiece.color));

            if (destinationPiece == null)
            {
                pieces[ply.from.toScalar()] = null;
                _shownSituation.set(ply.from, Hex.empty());
            }
            else if (departurePiece.color == destinationPiece.color && (departurePiece.type == Intellector && destinationPiece.type == Defensor || departurePiece.type == Defensor && destinationPiece.type == Intellector))
            {
                destinationPiece.reposition(ply.from, this);
                pieces[ply.from.toScalar()] = destinationPiece;
                _shownSituation.set(ply.from, Hex.occupied(destinationPiece.type, destinationPiece.color));
            }
            else
            {
                pieceLayer.removeChild(destinationPiece);
                pieces[ply.from.toScalar()] = null;
                _shownSituation.set(ply.from, Hex.empty());
            }
        }
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
            _shownSituation.set(transform.coords, goalHex);
        }
        _shownSituation.turnColor = opposite(_shownSituation.turnColor);
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

        var shift:Point = new Point(hexWidth/2, hexHeight/2);

        var p:Point = new Point(0, 0);
        p.x = 3 * hexSideLength * i / 2;
        p.y = hexHeight * j;

        if (i % 2 == 1)
            p.y += hexHeight / 2;

        return p.add(shift);
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
            producePiece(p, _shownSituation.get(p));
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
            piece.reposition(location, this);
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

    private function drawLetters() 
    {
        for (i in 0...9)
        {
            var bottomHexLocation:IntPoint = new IntPoint(i, orientationColor == White? 6 - i % 2 : 0);
            var bottomHexCoords:Point = hexCoords(bottomHexLocation);
            var letter:Label = createLetter(Notation.getColumn(i), hexSideLength);
            letter.width = 2 * hexSideLength;
            letter.x = bottomHexCoords.x - hexSideLength;
            letter.y = bottomHexCoords.y + Hexagon.sideToHeight(hexSideLength) / 2;
            letters.push(letter);
            hexagonLayer.addChild(letter); 
        }
    }

    private function removeLetters()
    {
        for (letter in letters)
            hexagonLayer.removeChild(letter);
        letters = [];
    }

    private function createLetter(letter:String, hexSideLength:Float):Label 
    {
        var tf = new Label();
        tf.customStyle = {fontSize: MathUtils.intScaleLike(28, 40, hexSideLength), color: Colors.border, fontBold: true, textAlign: "center"};
        tf.text = letter;
        return tf;
    }

    private function updateMarkup()
    {
        var markup:Markup = Preferences.markup.get();

        var lettersWerePresent:Bool = this.lettersEnabled;
        var lettersWillBePresent:Bool = markup != None;

        if (lettersWerePresent && !lettersWillBePresent)
            removeLetters();
        else if (!lettersWerePresent && lettersWillBePresent)
            drawLetters();

        for (hexagon in hexagons)
            hexagon.setNumberVisibility(markup == Over);

        this.lettersEnabled = lettersWillBePresent;
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, hexSideLength:Float = 40, enforcedMarkup:Null<Markup> = null) 
    {
        super();
        var markup:Markup = enforcedMarkup == null? Preferences.markup.get() : enforcedMarkup;

        this.hexSideLength = hexSideLength;
        this.lettersEnabled = markup != None;
        this.orientationColor = orientationColor;
        this._shownSituation = situation.copy();
        this.hexagonLayer = new Sprite();
        this.pieceLayer = new Sprite();

        addChild(hexagonLayer);
        addChild(pieceLayer);

        produceHexagons(markup == Over);
        producePieces();
        if (lettersEnabled)
            drawLetters();
    }

}