package gameboard;

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
    public var lettersEnabled(default, null):Bool;

    public var hexagons:Array<Hexagon>;
    public var pieces:Array<Null<Piece>>;

    public var orientationColor(default, null):PieceColor;

    private var _shownSituation:Situation;
    public var shownSituation(get, never):Situation;

    private var letters:Array<Label> = [];

    private var hexagonLayer:Absolute;
    private var pieceLayer:Absolute;

    private var resizeData:ResizeData;

    private function get_shownSituation():Situation
    {
        return _shownSituation.copy();
    }
    
    @:bind(this, UIEvent.RESIZE)
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

        if (lettersEnabled)
        {
            removeLetters();
            drawLetters();
        }
        
        resizeData = new ResizeData(width, height, now);
    }

    public function setOrientation(val:PieceColor) 
    {
        if (val == orientationColor)
            return;

        orientationColor = val;

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

    public function setShownSituation(val:Situation)
    {
        for (piece in pieces)
            pieceLayer.removeComponent(piece);
        pieces = [];
        _shownSituation = val.copy();
        producePieces();
    }

    public function clearPieces()
    {
        setShownSituation(Situation.empty());
    }

    public function setHexDirectly(location:HexCoords, hex:Hex)
    {
        if (hex.type() == Intellector)
        {
            var oldIntellectorPosition:Null<HexCoords> = _shownSituation.intellectorCoords(hex.color());
            if (oldIntellectorPosition != null)
            {
                pieceLayer.removeComponent(getPiece(oldIntellectorPosition));
                pieces[oldIntellectorPosition.toScalarCoord()] = null;
                _shownSituation.set(oldIntellectorPosition, Empty);
            }
        }
        var formerPiece = getPiece(location);
        if (formerPiece != null)
            pieceLayer.removeComponent(formerPiece);
        producePiece(location, hex);
        _shownSituation.set(location, hex);
    }

    public function applyPremoveTransposition(ply:RawPly) 
    {
        var departurePiece = getPiece(ply.from);
        var destinationPiece = getPiece(ply.to);

        if (ply.morphInto != null)
        {
            pieceLayer.removeComponent(departurePiece);
            pieces[ply.from.toScalarCoord()] = null;
            _shownSituation.set(ply.from, Empty);

            if (destinationPiece != null)
                pieceLayer.removeComponent(destinationPiece);
            producePiece(ply.to, Hex.construct(ply.morphInto, departurePiece.pieceColor));
            _shownSituation.set(ply.to, Hex.construct(ply.morphInto, departurePiece.pieceColor));
        }
        else
        {
            departurePiece.setCenterAt(hexCoords(ply.to));
            pieces[ply.to.toScalarCoord()] = departurePiece;
            _shownSituation.set(ply.to, Hex.construct(departurePiece.pieceType, departurePiece.pieceColor));

            if (destinationPiece == null)
            {
                pieces[ply.from.toScalarCoord()] = null;
                _shownSituation.set(ply.from, Empty);
            }
            else if (departurePiece.pieceColor == destinationPiece.pieceColor && (departurePiece.pieceType == Intellector && destinationPiece.pieceType == Defensor || departurePiece.pieceType == Defensor && destinationPiece.pieceType == Intellector))
            {
                destinationPiece.setCenterAt(hexCoords(ply.from));
                pieces[ply.from.toScalarCoord()] = destinationPiece;
                _shownSituation.set(ply.from, Hex.construct(destinationPiece.pieceType, destinationPiece.pieceColor));
            }
            else
            {
                pieceLayer.removeComponent(destinationPiece);
                pieces[ply.from.toScalarCoord()] = null;
                _shownSituation.set(ply.from, Empty);
            }
        }
    }

    public function applyMoveTransposition(ply:MaterializedPly, backInTime:Bool = false)
    {
        switch ply
        {
            case NormalMove(from, to, _):
                if (!backInTime)
                    movePiece(from, to);
                else
                    movePiece(to, from);
            case NormalCapture(from, to, _, capturedPiece):
                if (!backInTime)
                    movePiece(from, to);
                else
                {
                    movePiece(to, from);
                    addPiece(to, Hex.construct(capturedPiece, _shownSituation.turnColor));
                }
            case ChameleonCapture(from, to, capturingPiece, capturedPiece):
                if (!backInTime)
                    movePiece(from, to, capturedPiece);
                else
                {
                    movePiece(to, from, capturingPiece);
                    addPiece(to, Hex.construct(capturedPiece, _shownSituation.turnColor));
                }
            case Promotion(from, to, promotedTo):
                if (!backInTime)
                    movePiece(from, to, promotedTo);
                else
                    movePiece(to, from, Progressor);
            case PromotionWithCapture(from, to, capturedPiece, promotedTo):
                if (!backInTime)
                    movePiece(from, to, promotedTo);
                else
                {
                    movePiece(to, from, Progressor);
                    addPiece(to, Hex.construct(capturedPiece, _shownSituation.turnColor));
                }
            case Castling(from, to):
                swapPieces(from, to);
        }
       
        if (!backInTime)
            _shownSituation.performPly(ply);
        else
            _shownSituation.revertPly(ply);
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

    private function movePiece(coords:HexCoords, newCoords:HexCoords, ?newType:PieceType)
    {
        var s = coords.toScalarCoord();
        var newS = newCoords.toScalarCoord();
        var piece = pieces[s];
        var capturedPiece = pieces[newS];

        if (piece == null)
            return;

        if (capturedPiece != null)
            pieceLayer.removeComponent(capturedPiece);

        pieces[s] = null;

        if (newType != null)
        {
            pieceLayer.removeComponent(piece);

            var hex:Hex = Hex.construct(newType, piece.pieceColor);
            producePiece(newCoords, hex);
        }
        else
        {
            piece.setCenterAt(hexCoords(newCoords));
            pieces[newS] = piece;
        }
    }

    private function swapPieces(coords1:HexCoords, coords2:HexCoords)
    {
        var piece1 = getPiece(coords1);
        var piece2 = getPiece(coords2);

        if (piece1 == null || piece2 == null)
            return;

        piece1.setCenterAt(hexCoords(coords2));
        piece2.setCenterAt(hexCoords(coords1));

        pieces[coords2.toScalarCoord()] = piece1;
        pieces[coords1.toScalarCoord()] = piece2;
    }

    private function addPiece(coords:HexCoords, hex:Hex)
    {
        var s = coords.toScalarCoord();
        
        removePiece(coords);

        if (!hex.isEmpty())
        {
            producePiece(coords, hex);
        }
    }

    private function removePiece(coords:HexCoords)
    {
        var s = coords.toScalarCoord();
        var piece = pieces[s];

        if (piece == null)
            return;

        pieceLayer.removeComponent(piece);

        pieces[s] = null;
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
        return absHexCoords(location.i, location.j, orientationColor == White);
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
            producePiece(p, _shownSituation.get(p));
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
        for (i in 0...9)
        {
            var bottomHexLocation:HexCoords = new HexCoords(i, orientationColor == White? 6 - i % 2 : 0);
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
        var sideLengthByHeight:Float = HexDimensions.heightToSide(height / (lettersEnabled? 7.5 : 7)) / 1.15;
        var sideLength:Float = Math.min(sideLengthByWidth, sideLengthByHeight);

        return new HexDimensions(sideLength);
    }

    private function updateMarking()
    {
        var marking:Marking = Preferences.marking.get();

        var lettersWerePresent:Bool = this.lettersEnabled;
        var lettersWillBePresent:Bool = marking != None;

        if (lettersWerePresent && !lettersWillBePresent)
            removeLetters();
        else if (!lettersWerePresent && lettersWillBePresent)
            drawLetters();

        for (scalarCoord => hexagon in hexagons.keyValueIterator())
            if (marking == Over)
            {
                var hexCoords:HexCoords = HexCoords.fromScalarCoord(scalarCoord);
                var rowMark:String = Notation.getRow(hexCoords.i, hexCoords.j);
                hexagon.setDisplayedRowNumber(rowMark);
            }
            else
                hexagon.setDisplayedRowNumber(null);

        this.lettersEnabled = lettersWillBePresent;
    }

    //TODO: Signature updated
    //TODO: Marking put in separate class
    //TODO: Default marking from preferences is now on the caller
    public function new(situation:Situation, orientationColor:PieceColor = White, ?marking:Marking, ?initialWidth:Float = 250, ?initialHeight:Float = 250) 
    {
        super();
        this.width = initialWidth;
        this.height = initialHeight;
        this.resizeData = new ResizeData(initialWidth, initialHeight, -1);

        if (marking == null)
            marking = None;

        this.lettersEnabled = marking != None;
        this.orientationColor = orientationColor;
        this._shownSituation = situation.copy();
        this.hexagonLayer = new Absolute();
        this.pieceLayer = new Absolute();

        this.dimensions = getDimensions();

        addComponent(hexagonLayer);
        addComponent(pieceLayer);

        produceHexagons(marking == Over);
        producePieces();
        if (lettersEnabled)
            drawLetters();
    }

}