package gameboard_revamped;

import gfx.utils.Colors;
import gameboard.util.Marking;
import gameboard.components.Hexagon;
import gameboard.components.Piece;
import gameboard.util.HexDimensions;
import haxe.ui.util.Color;
import haxe.ui.core.Screen;
import js.Browser;
import haxe.Timer;
import haxe.ui.events.UIEvent;
import net.shared.converters.Notation;
import net.shared.PieceType;
import net.shared.PieceColor;
import net.shared.board.MaterializedPly;
import net.shared.board.RawPly;
import net.shared.board.HexCoords;
import net.shared.board.Hex;
import net.shared.board.Situation;
import haxe.ui.containers.Absolute;
import haxe.ui.geom.Point;
import haxe.ui.components.Label;

private class ResizeData
{
    public var renderedForWidth:Float;
    public var renderedForHeight:Float;
    public var lastResized:Float;

    public var delayedResizeTimer:Null<Timer> = null;

    public function new(renderedForWidth:Float, renderedForHeight:Float, lastResized:Float)
    {
        this.renderedForWidth = renderedForWidth;
        this.renderedForHeight = renderedForHeight;
        this.lastResized = lastResized;
    }
}

/**
    A simplest board with a very basic functionality
**/
class Board extends Absolute
{
    public var dimensions(default, null):HexDimensions;
    private var resizeData:ResizeData;

    private var hexagonLayer:Absolute;
    private var pieceLayer:Absolute;

    public var hexagons:Array<Hexagon>;
    public var pieces:Array<Null<Piece>>;
    private var letters:Array<Label> = [];

    private var shownSituation:Situation;
    private var orientation:PieceColor;
    private var lettersShown:Bool;
    
    public function resize(?e:UIEvent)
    {
        var now:Float = Timer.stamp();
        var secsSinceLastResize:Float = now - resizeData.lastResized;

        if (secsSinceLastResize < 0.5)
        {
            if (resizeData.delayedResizeTimer == null)
                resizeData.delayedResizeTimer = Timer.delay(resize.bind(null), Math.ceil((0.5 - secsSinceLastResize) * 1000));
            return;
        }

        if (width == null || height == null)
            return;

        if (resizeData.renderedForWidth == width && resizeData.renderedForHeight == height)
            return;

        dimensions = getDimensions();
            
        for (s in HexCoords.enumerateScalar())
        {
            var location:HexCoords = HexCoords.fromScalarCoord(s);
            var position:Point = hexCoords(location);

            var hexagon = hexagons[s];
            var piece = pieces[s];

            hexagon.resize(dimensions, position);
            if (piece != null)
                piece.resize(dimensions, position);
        }

        if (lettersShown)
        {
            removeLetters();
            drawLetters();
        }
        
        resizeData = new ResizeData(width, height, now);
    }

    public function setOrientation(newOrientation:PieceColor) 
    {
        if (orientation == newOrientation)
            return;

        orientation = newOrientation;

        for (s in HexCoords.enumerateScalar())
        {
            var coords = hexCoords(HexCoords.fromScalarCoord(s));

            var hexagon = hexagons[s];
            var piece = pieces[s];

            hexagon.setCenterAt(coords);
            if (piece != null)
                piece.setCenterAt(coords);
        }

        if (!Lambda.empty(letters))
            swapLetters();
    }

    private function setShownSituation(newShownSituation:Situation)
    {
        for (piece in pieces)
            pieceLayer.removeComponent(piece);
        pieces = [];
        shownSituation = newShownSituation;
        producePieces();
    }

    public function getHex(coords:Null<HexCoords>):Null<Hexagon>
    {
        if (hexExists(coords))
            return hexagons[coords.toScalarCoord()];
        else
            return null;
    }
    
    public function getPiece(coords:Null<HexCoords>):Null<Piece>
    {
        if (hexExists(coords))
            return pieces[coords.toScalarCoord()];
        else
            return null;
    }

    public static function hexExists(p:Null<HexCoords>):Bool
    {
        if (p != null)
            return p.isValid();
        else
            return null;
    }
    
    private function posToIndexes(localEventCoords:Point):Null<HexCoords>
    {
        var closest:Null<HexCoords> = null;
        var distanceSqr:Float = dimensions.sideLength * dimensions.sideLength;

        for (j in 0...7)
            for (i in 0...9)
            {
                var loc = new HexCoords(i, j);
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

    public function hexCoords(location:HexCoords):Point
    {
        return absHexCoords(location.i, location.j, orientation == White);
    }

    private function absHexCoords(i:Int, j:Int, isOrientationNormal:Bool):Point
    {
        if (!isOrientationNormal)
        {
            j = 6 - j - i % 2;
            i = 8 - i;
        }

        var boardCenter:Point = new Point(width / 2, height / 2);

        var di:Float = i - 4;
        var dj:Float = j - 3;

        var shiftX:Float = 1.5 * di * dimensions.sideLength;
        var shiftY:Float = dj * dimensions.height;

        if (Math.abs(di % 2) == 1)
            shiftY += dimensions.height / 2;

        var shift:Point = new Point(shiftX, shiftY);

        return boardCenter.sum(shift);
    }

    private function produceHexagons(displayRowNumbers:Bool)
    {
        hexagons = [];

        for (s in HexCoords.enumerateScalar())
        {
            var location:HexCoords = HexCoords.fromScalarCoord(s);
            var position:Point = hexCoords(location);
            var displayedRowNumber:Null<String> = displayRowNumbers? Notation.getRow(location.i, location.j) : null;
            var hexagon:Hexagon = new Hexagon(dimensions, location.isDark(), displayedRowNumber, position);
            hexagonLayer.addComponent(hexagon);
            hexagons.push(hexagon);
        }
    }

    private function producePieces()
    {
        pieces = [];

        for (s in 0...59)
        {
            var p = HexCoords.fromScalarCoord(s);
            producePiece(p, shownSituation.get(p));
        }
    }

    private function producePiece(location:HexCoords, hex:Hex)
    {
        var scalarCoord = location.toScalarCoord();

        switch hex 
        {
            case Empty:
                pieces[scalarCoord] = null;
            case Occupied(pieceData):
                var position:Point = hexCoords(location);
                var piece:Piece = Piece.fromData(pieceData, dimensions, position);
                pieceLayer.addComponent(piece);
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
        if (!Lambda.empty(letters))
            removeLetters();

        for (i in 0...9)
        {
            var bottomHexLocation:HexCoords = new HexCoords(i, orientation == White? 6 - i % 2 : 0);
            var bottomHexCoords:Point = hexCoords(bottomHexLocation);
            var letter:Label = createLetter(Notation.getColumn(i));
            letter.width = dimensions.width;
            letter.left = bottomHexCoords.x - dimensions.width / 2;
            letter.top = bottomHexCoords.y + dimensions.height / 2;
            letters.push(letter);
            hexagonLayer.addComponent(letter); 
        }
    }

    private function removeLetters()
    {
        for (letter in letters)
            hexagonLayer.removeComponent(letter);
        letters = [];
    }

    private function createLetter(letter:String):Label 
    {
        var tf = new Label();
        tf.customStyle = {fontSize: 0.7 * dimensions.sideLength, color: Colors.border, fontBold: true, textAlign: "center"};
        tf.text = letter;
        return tf;
    }

    private function getDimensions():HexDimensions
    {
        var sideLengthByWidth:Float = width / 14.15;
        var sideLengthByHeight:Float = HexDimensions.heightToSide(height / (lettersShown? 7.5 : 7)) / 1.15;
        var sideLength:Float = Math.min(sideLengthByWidth, sideLengthByHeight);

        return new HexDimensions(sideLength);
    }

    private function updateMarking()
    {
        var actualMarking:Marking = Preferences.marking.get();
        var showLetters:Bool = actualMarking.match(Side | Over);
        var showNumbers:Bool = actualMarking.match(Over);

        if (showLetters && !lettersShown)
            drawLetters();
        else if (!showLetters && lettersShown)
            removeLetters();
            
        for (scalarCoord => hexagon in hexagons.keyValueIterator())
            if (showNumbers)
            {
                var hexCoords:HexCoords = HexCoords.fromScalarCoord(scalarCoord);
                var rowMark:String = Notation.getRow(hexCoords.i, hexCoords.j);
                hexagon.setDisplayedRowNumber(rowMark);
            }
            else
                hexagon.setDisplayedRowNumber(null);
    }

    public function new(situation:Situation, orientationColor:PieceColor = White, ?marking:Marking, ?initialWidth:Float = 250, ?initialHeight:Float = 250, ?dontResize:Bool = false) 
    {
        super();
        this.width = initialWidth;
        this.height = initialHeight;
        this.resizeData = new ResizeData(initialWidth, initialHeight, -1);

        if (marking == null)
            marking = None;

        this.lettersShown = marking != None;
        this.orientation = orientationColor;
        this.shownSituation = situation.copy();
        this.hexagonLayer = new Absolute();
        this.pieceLayer = new Absolute();

        this.dimensions = getDimensions();

        addComponent(hexagonLayer);
        addComponent(pieceLayer);

        produceHexagons(marking == Over);
        producePieces();
        if (lettersShown)
            drawLetters();

        if (!dontResize)
            registerEvent(UIEvent.RESIZE, resize);
    }

}