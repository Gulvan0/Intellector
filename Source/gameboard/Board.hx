package gameboard;

import net.shared.utils.MathUtils;
import net.shared.converters.Notation;
import net.shared.PieceType;
import net.shared.board.MaterializedPly;
import net.shared.board.RawPly;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.board.Situation;
import Preferences.Markup;
import haxe.ui.components.Label;
import openfl.display.Sprite;
import gfx.utils.Colors;
import openfl.geom.Point;
import net.shared.PieceColor;

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
        for (s in HexCoords.enumerateScalar())
        {
            var coords = hexCoords(HexCoords.fromScalarCoord(s));

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

            for (s in HexCoords.enumerateScalar())
            {
                var coords = hexCoords(HexCoords.fromScalarCoord(s));

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

    public function setHexDirectly(location:HexCoords, hex:Hex)
    {
        if (hex.type() == Intellector)
        {
            var oldIntellectorPosition:Null<HexCoords> = _shownSituation.intellectorCoords(hex.color());
            if (oldIntellectorPosition != null)
            {
                pieceLayer.removeChild(getPiece(oldIntellectorPosition));
                pieces[oldIntellectorPosition.toScalarCoord()] = null;
                _shownSituation.set(oldIntellectorPosition, Empty);
            }
        }
        var formerPiece = getPiece(location);
        if (formerPiece != null)
            pieceLayer.removeChild(formerPiece);
        producePiece(location, hex);
        _shownSituation.set(location, hex);
    }

    public function applyPremoveTransposition(ply:RawPly) 
    {
        var departurePiece = getPiece(ply.from);
        var destinationPiece = getPiece(ply.to);

        if (ply.morphInto != null)
        {
            pieceLayer.removeChild(departurePiece);
            pieces[ply.from.toScalarCoord()] = null;
            _shownSituation.set(ply.from, Empty);

            if (destinationPiece != null)
                pieceLayer.removeChild(destinationPiece);
            producePiece(ply.to, Hex.construct(ply.morphInto, departurePiece.color));
            _shownSituation.set(ply.to, Hex.construct(ply.morphInto, departurePiece.color));
        }
        else
        {
            departurePiece.reposition(ply.to, this);
            pieces[ply.to.toScalarCoord()] = departurePiece;
            _shownSituation.set(ply.to, Hex.construct(departurePiece.type, departurePiece.color));

            if (destinationPiece == null)
            {
                pieces[ply.from.toScalarCoord()] = null;
                _shownSituation.set(ply.from, Empty);
            }
            else if (departurePiece.color == destinationPiece.color && (departurePiece.type == Intellector && destinationPiece.type == Defensor || departurePiece.type == Defensor && destinationPiece.type == Intellector))
            {
                destinationPiece.reposition(ply.from, this);
                pieces[ply.from.toScalarCoord()] = destinationPiece;
                _shownSituation.set(ply.from, Hex.construct(destinationPiece.type, destinationPiece.color));
            }
            else
            {
                pieceLayer.removeChild(destinationPiece);
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
            pieceLayer.removeChild(capturedPiece);

        pieces[s] = null;

        if (newType != null)
        {
            pieceLayer.removeChild(piece);

            var hex:Hex = Hex.construct(newType, piece.color);
            producePiece(newCoords, hex);
        }
        else
        {
            piece.reposition(newCoords, this);
            pieces[newS] = piece;
        }
    }

    private function swapPieces(coords1:HexCoords, coords2:HexCoords)
    {
        var piece1 = getPiece(coords1);
        var piece2 = getPiece(coords2);

        if (piece1 == null || piece2 == null)
            return;

        piece1.reposition(coords2, this);
        piece2.reposition(coords1, this);

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

        pieceLayer.removeChild(piece);

        pieces[s] = null;
    }

    public static function hexExists(p:Null<HexCoords>):Bool
    {
        if (p != null)
            return p.isValid();
        else
            return null;
    }
    
    private function posToIndexes(stageX:Float, stageY:Float):Null<HexCoords>
    {
        var localEventCoords:Point = globalToLocal(new Point(stageX, stageY));
        var closest:Null<HexCoords> = null;
        var distanceSqr:Float = hexSideLength * hexSideLength;

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

        for (s in HexCoords.enumerateScalar())
        {
            var p:HexCoords = HexCoords.fromScalarCoord(s);
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
                var piece:Piece = Piece.fromData(pieceData, hexSideLength);
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
            var bottomHexLocation:HexCoords = new HexCoords(i, orientationColor == White? 6 - i % 2 : 0);
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