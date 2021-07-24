package analysis;

import struct.PieceColor;

enum ScoreType
{
    Mate(turns:Int, winner:PieceColor);
    Normal(value:Float);
}

abstract Score(ScoreType) from ScoreType to ScoreType
{
    @:op(A > B)
    public function greater(other:ScoreType) 
    {
        switch this 
        {
            case Mate(turns1, winner1):
                switch other 
                {
                    case Mate(turns2, winner2):
                        if (winner1 == winner2)
                            return turns1 < turns2;
                        else
                            return winner1 == White;
                    case Normal(value2):
                        return winner1 == White;
                }
            case Normal(value1):
                switch other 
                {
                    case Mate(turns2, winner2):
                        return winner2 == Black;
                    case Normal(value2):
                        return value1 > value2;
                }
        }
    }

    @:op(A == B)
    public function equal(other:ScoreType) 
    {
        switch this 
        {
            case Mate(turns1, winner1):
                switch other 
                {
                    case Mate(turns2, winner2):
                        return turns1 == turns2 && winner1 == winner2;
                    case Normal(value2):
                        return false;
                }
            case Normal(value1):
                switch other 
                {
                    case Mate(turns2, winner2):
                        return false;
                    case Normal(value2):
                        return value1 == value2;
                }
        }
    }

    @:op(A >= B)
    public function ge(other:ScoreType) 
    {
        return equal(other) || greater(other);
    }

    @:op(A < B)
    public function less(other:ScoreType) 
    {
        return !ge(other);
    }

    @:op(A <= B)
    public function le(other:ScoreType) 
    {
        return !greater(other);
    }

    public inline function incrementedMate():Score
    {
        return switch this 
        {
            case Mate(turns, winner): Mate(turns + 1, winner);
            default: this;
        }
    }

    public function new(v:ScoreType) 
    {
        this = v;    
    }
}