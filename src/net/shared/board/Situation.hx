package net.shared.board;

import haxe.Unserializer;
import haxe.Serializer;
import net.shared.utils.MathUtils;
import net.shared.converters.SituationSerializer;
import net.shared.PieceColor;
import net.shared.PieceType.letter as pieceLetter;

class OccupiedHexData
{
    public final scalarCoord:Int;
    public final piece:PieceData;

    public function new(scalarCoord:Int, piece:PieceData) 
    {
        this.scalarCoord = scalarCoord;
        this.piece = piece;
    }
}

class Situation
{
    public var pieces:PieceArrangement;
    public var turnColor(default, null):PieceColor;
    private var intellectorPos:Map<PieceColor, HexCoords>;

    private static var defaultStartingHash:String = defaultStarting().getHash();

    public static function defaultStarting():Situation
    {
        return new Situation(PieceArrangement.defaultStarting(), White, [White => new HexCoords(4, 6), Black => new HexCoords(4, 0)]);
    }

    public static function empty():Situation
    {
        return new Situation(PieceArrangement.emptyArrangement(), White, []);
    }

    public static function randomPlay(plyCount:Int):Situation 
    {
        var sit:Situation = Situation.defaultStarting();
        for (i in 0...plyCount)
            sit.performRandomPly();
        return sit;
    }

    @:keep
    private function hxSerialize(s:Serializer) 
    {
        s.serialize(serialize());
    }

    @:keep
    private function hxUnserialize(u:Unserializer) 
    {
        var sit:Situation = deserialize(u.unserialize());

        pieces = sit.pieces;
        turnColor = sit.turnColor;
        intellectorPos = sit.intellectorPos;
    }

    public static function deserialize(sip:String):Null<Situation>
    {
        return SituationSerializer.deserialize(sip);
    }

    public function serialize():String
    {
        return SituationSerializer.serialize(this);
    }

    public function symmetrical():Situation
    {
        var sit:Situation = Situation.empty();

        for (coords in HexCoords.enumerate())
            sit.set(coords.horizontalReflection(), get(coords));

        return sit;
    }

    public function isValidStarting():Bool
    {
        var whiteIntPos = intellectorPos.get(White);
        var blackIntPos = intellectorPos.get(Black);

        if (whiteIntPos == null || whiteIntPos.isFinal(White))
            return false;
        else if (blackIntPos == null || blackIntPos.isFinal(Black))
            return false;
        else if (whiteIntPos.equals(blackIntPos))
            return false;
        else
            return true;
    }

    public function countPieces():Int
    {
        var cnt:Int = 0;

        for (coords in HexCoords.enumerate()) 
        {
            switch get(coords) 
            {
                case Occupied(_):
                    cnt++;
                default:
            }
        }

        return cnt;
    }

    public function collectPieces():Map<HexCoords, PieceData>
    {
        var map:Map<HexCoords, PieceData> = [];

        for (coords in HexCoords.enumerate()) 
        {
            switch get(coords) 
            {
                case Occupied(piece):
                    map.set(coords, piece);
                default:
            }
        }

        return map;
    }

    /**
        Always the same order of hexes, but the returned structure is less convenient
    **/
    public function collectPiecesStable():Array<OccupiedHexData>
    {
        var list:Array<OccupiedHexData> = [];

        for (coord in HexCoords.enumerateScalar()) 
        {
            switch getS(coord) 
            {
                case Occupied(piece):
                    list.push(new OccupiedHexData(coord, piece));
                default:
            }
        }

        return list;
    }

    public function isDefaultStarting():Bool
    {
        return getHash() == defaultStartingHash;
    }

    public function getHash():String
    {
        var hash:String = "";

        for (hexData in collectPiecesStable())
        {
            hash += hexData.scalarCoord;
            hash += pieceLetter(hexData.piece.type);
            if (hexData.piece.color == Black)
                hash += "!";
        }

        return hash;
    }

    public function intellectorCoords(color:PieceColor):HexCoords 
    {
        return intellectorPos.get(color);
    }

    public function availablePlys():Array<RawPly>
    {
        return Rules.possiblePlys(this);
    }

    public function situationAfterRawPly(ply:RawPly):Situation
    {
        return situationAfterPly(ply.toMaterialized(this));
    }

    public function situationAfterPly(ply:MaterializedPly):Situation
    {
        var situation:Situation = copy();
        situation.performPly(ply);
        return situation;
    }

    public function performRandomPly()
    {
        var allPlys = availablePlys();
        var randomPly = MathUtils.randomElement(allPlys);
        performRawPly(randomPly);
    }

    public function performRawPly(ply:RawPly):PerformPlyResult
    {
        return performPly(ply.toMaterialized(this));
    }

    public function performPly(ply:MaterializedPly):PerformPlyResult
    {
        if (!Rules.isPossible(ply.toRaw(), this))
            return FailedToPerform;
        
        var isMate:Bool = ply.isMating();
        var isBreakthrough:Bool = isMate? false : ply.isBreakthrough(pieces, turnColor);
        var isProgressive:Bool = isBreakthrough? false : ply.isProgressive();

        switch ply 
        {
            case NormalMove(from, to, movingPiece):
                set(from, Empty);
                set(to, Hex.construct(movingPiece, turnColor));
            case NormalCapture(from, to, capturingPiece, _):
                set(from, Empty);
                set(to, Hex.construct(capturingPiece, turnColor));
            case ChameleonCapture(from, to, _, capturedPiece):
                set(from, Empty);
                set(to, Hex.construct(capturedPiece, turnColor));
            case Promotion(from, to, promotedTo), PromotionWithCapture(from, to, _, promotedTo):
                set(from, Empty);
                set(to, Hex.construct(promotedTo, turnColor));
            case Castling(from, to):
                var tmp:Hex = get(from);
                set(from, get(to));
                set(to, tmp);
        }

        turnColor = opposite(turnColor);
        
        if (isMate)
            return MateReached;
        else if (isBreakthrough)
            return BreakthroughReached;
        else if (isProgressive)
            return ProgressivePlyPerformed(ply);
        else
            return NormalPlyPerformed(ply);
    }

    public function revertPly(ply:MaterializedPly)
    {
        turnColor = opposite(turnColor);

        switch ply 
        {
            case NormalMove(from, to, _):
                set(from, get(to));
                set(to, Empty);
            case NormalCapture(from, to, _, capturedPiece):
                set(from, get(to));
                set(to, Hex.construct(capturedPiece, opposite(turnColor)));
            case ChameleonCapture(from, to, capturingPiece, capturedPiece):
                set(from, Hex.construct(capturingPiece, turnColor));
                set(to, Hex.construct(capturedPiece, opposite(turnColor)));
            case Promotion(from, to, _):
                set(from, Hex.construct(Progressor, turnColor));
                set(to, Empty);
            case PromotionWithCapture(from, to, capturedPiece, _):
                set(from, Hex.construct(Progressor, turnColor));
                set(to, Hex.construct(capturedPiece, opposite(turnColor)));
            case Castling(from, to):
                var tmp:Hex = get(from);
                set(from, get(to));
                set(to, tmp);
        }
    }

    public inline function getS(scalarCoord:Int):Hex
    {
        return get(HexCoords.fromScalarCoord(scalarCoord));
    }

    public inline function get(coords:HexCoords):Hex
    {
        return pieces.get(coords);
    }

    public inline function set(coords:HexCoords, hex:Hex, ?adjustToConsistency:Bool = true) 
    {
        if (adjustToConsistency)
        {
            if (get(coords).type() == Intellector)
                intellectorPos.remove(get(coords).color());
            if (hex.type() == Intellector)
                intellectorPos.set(hex.color(), coords);
        }
        pieces.set(coords, hex);  
    }

    public function copy(?newTurnColor:PieceColor):Situation
    {
        return new Situation(pieces.copy(), newTurnColor ?? turnColor, intellectorPos.copy());
    }

    public function equals(otherSituation:Situation):Bool
    {
        return getHash() == otherSituation.getHash();
    }

    public function toString():String
    {
        return 'Situation';  
    }

    public function new(pieces:PieceArrangement, turnColor:PieceColor, intellectorPos:Map<PieceColor, HexCoords>)
    {
        this.pieces = pieces;
        this.turnColor = turnColor;
        this.intellectorPos = intellectorPos;
    }
}