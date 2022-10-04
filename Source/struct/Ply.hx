package struct;

import serialization.PlySerializer;
import utils.Notation;
import net.shared.PieceType;

using StringTools;

class Ply 
{
    public var from:IntPoint;
    public var to:IntPoint;
    public var morphInto:Null<PieceType>;

    public static function construct(from:IntPoint, to:IntPoint, ?morphInto:PieceType) 
    {
        var ply:Ply = new Ply();
        ply.from = from;
        ply.to = to;
        ply.morphInto = morphInto;
        return ply;
    }

    public static function plySequenceToNotation(plys:Array<Ply>, startingSituation:Situation):Array<String>
    {
        var plyStrSeq = [];
        var situation = startingSituation.copy();

        for (ply in plys)
        {
            plyStrSeq.push(ply.toNotation(situation));
            situation = situation.makeMove(ply);
        }

        return plyStrSeq;
    }

    public static function fromNotation(plyStr:String, context:Situation):Ply
    {
        return Notation.plyFromNotation(plyStr, context);
    }

    public function toNotation(context:Situation, ?indicateColor:Bool):String
    {
        return Notation.plyToNotation(this, context, indicateColor);
    }

    public static function deserialize(plyStr:String):Ply
    {
        return PlySerializer.deserialize(plyStr);
    }

    public function serialize():String
    {
        return PlySerializer.serialize(this);
    }

    public function modifiedHexes():Array<IntPoint>
    {
        return [from.copy(), to.copy()];
    }

    public function copy():Ply
    {
        var ply:Ply = new Ply();
        ply.from = this.from;
        ply.to = this.to;
        ply.morphInto = this.morphInto;
        return ply;    
    }

    public function equals(p:Ply):Bool
    {
        return this.from == p.from && this.to == p.to && this.morphInto == p.morphInto;
    }

    public function toReversible(context:Situation):ReversiblePly
    {
        var reversible:ReversiblePly = [];

        var forecasted:Situation = context.makeMove(this);

        var formerFrom:Hex = context.get(from);
        var formerTo:Hex = context.get(to);
        var latterFrom:Hex = forecasted.get(from);
        var latterTo:Hex = forecasted.get(to);

        reversible.push(new HexTransform(from, formerFrom, latterFrom));
        reversible.push(new HexTransform(to, formerTo, latterTo));

        return reversible;
    }

    public function new() 
    {
        
    }
}