package analysis;

import struct.Situation;

class AlphaBeta 
{
    private function evaluateHeuristic(situation:Situation):Float
    {
        var value:Float = 0;
        for (coords => hex in situation.collectOccupiedHexes()) 
            if (hex.color == White)
                value += PieceValues.posValue(hex.type, coords.i, coords.j);
            else
                value -= PieceValues.posValue(hex.type, coords.i, coords.j);
        return value;
    }
}