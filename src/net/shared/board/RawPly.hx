package net.shared.board;

import net.shared.converters.PlySerializer;
import net.shared.converters.Notation;

class RawPly 
{
    public var from:HexCoords;
    public var to:HexCoords;
    public var morphInto:Null<PieceType>;

    public static function construct(from:HexCoords, to:HexCoords, ?morphInto:PieceType):RawPly
    {
        var ply:RawPly = new RawPly();
        ply.from = from;
        ply.to = to;
        ply.morphInto = morphInto;
        return ply;
    }

    public static function chameleon(from:HexCoords, to:HexCoords, situation:Situation):RawPly
    {
        var ply:RawPly = new RawPly();
        ply.from = from;
        ply.to = to;
        ply.morphInto = situation.get(to).type();
        return ply;
    }

    public static function fromNotation(plyStr:String, context:Situation):RawPly
    {
        return Notation.plyFromNotation(plyStr, context);
    }

    public function toNotation(context:Situation, ?indicateColor:Bool):String
    {
        return Notation.plyToNotation(this, context, indicateColor);
    }

    public static function deserialize(plyStr:String):RawPly
    {
        return PlySerializer.deserialize(plyStr);
    }

    public function serialize():String
    {
        return PlySerializer.serialize(this);
    }

    public function modifiedHexes():Array<HexCoords>
    {
        return [from.copy(), to.copy()];
    }

    public function copy():RawPly
    {
        var ply:RawPly = new RawPly();
        ply.from = this.from;
        ply.to = this.to;
        ply.morphInto = this.morphInto;
        return ply;    
    }

    public function equals(p:RawPly):Bool
    {
        return this.from == p.from && this.to == p.to && this.morphInto == p.morphInto;
    }

    public function toMaterialized(context:Situation):MaterializedPly
    {
        return MaterializedPly.construct(context.pieces, from, to, morphInto);
    }

    public function toString()
    {
        return '$from -> $to / Morph: $morphInto';
    }

    public function new() 
    {
        
    }
}