package analysis;

import struct.PieceType;

class PieceValues
{
    private static var dominatorManeurability:Array<Array<Null<Int>>> = [
        [14, 15, 14, 15, 14, 15, 14, 15, 14],
        [16, 17, 18, 19, 18, 19, 18, 17, 16],
        [18, 19, 20, 21, 22, 21, 20, 19, 18],
        [18, 19, 22, 21, 22, 21, 22, 19, 18],
        [18, 17, 20, 19, 22, 19, 20, 17, 18],
        [16, 15, 18, 15, 18, 15, 18, 15, 16],
        [14, null, 14, null, 14, null, 14, null, 14]
    ];
    private static var dominatorMaxManeurability:Int = 22;

    private static var defensorManeurability:Array<Array<Null<Int>>> = [
        [2, 5, 3, 5, 3, 5, 3, 5, 2],
        [4, 6, 6, 6, 6, 6, 6, 6, 4],
        [4, 6, 6, 6, 6, 6, 6, 6, 4],
        [4, 6, 6, 6, 6, 6, 6, 6, 4],
        [4, 6, 6, 6, 6, 6, 6, 6, 4],
        [4, 5, 6, 5, 6, 5, 6, 5, 4],
        [2, null, 3, null, 3, null, 3, null, 2]
    ];
    private static var defensorMaxManeurability:Int = 6;

    private static var aggressorManeurability:Array<Array<Null<Int>>> = [
        [8, null, 10, null, 12, null, 10, null, 8],
        [null, 9, null, 11, null, 11, null, 9, null],
        [null, null, null, null, null, null, null, null, null],
        [8, null, 12, null, 12, null, 12, null, 8],
        [null, 9, null, 11, null, 11, null, 9, null],
        [null, null, null, null, null, null, null, null, null],
        [8, null, 10, null, 12, null, 10, null, 8]
    ];
    private static var aggressorMaxManeurability:Int = 12;

    private static var oldLiberatorManeurability:Array<Array<Null<Int>>> = [
        [2, 2, 3, 3, 3, 3, 3, 2, 2],
        [3, 3, 5, 5, 5, 5, 5, 3, 3],
        [4, 4, 6, 6, 6, 6, 6, 4, 4],
        [4, 4, 6, 6, 6, 6, 6, 4, 4],
        [4, 3, 6, 5, 6, 5, 6, 3, 4],
        [3, 2, 5, 3, 5, 3, 5, 2, 3],
        [2, null, 3, null, 3, null, 3, null, 2]
    ];
    private static var oldLiberatorMaxManeurability:Int = 6;

    public static function posValue(type:Null<PieceType>, i:Int, j:Int) 
    {
        var strongMultiplier = switch type 
        {
            case Progressor: (i == 0 || i == 8)? 2/3 : 1;
            case Aggressor: aggressorManeurability[j][i] / aggressorMaxManeurability;
            case Dominator: dominatorManeurability[j][i] / dominatorMaxManeurability;
            case Liberator: (oldLiberatorManeurability[j][i] + 0.5 * defensorManeurability[j][i]) / (oldLiberatorMaxManeurability + 0.5 * defensorMaxManeurability);
            case Defensor: defensorManeurability[j][i] / defensorMaxManeurability;
            default: 0;
        };

        var weakenedMultiplier = MathUtils.avg(strongMultiplier, 1);
        return weakenedMultiplier * rawValue(type);
    }

    public static function rawValue(type:Null<PieceType>):Float
    {
        return switch type 
        {
            case Progressor: 1;
            case Aggressor: 1.75;
            case Dominator: 6;
            case Liberator: 2;
            case Defensor: 1.75;
            default: 0;
        }
    }

    public static inline function firstHasHigherPriority(type1:PieceType, type2:PieceType):Bool
    {
        if (type1 == Aggressor && type2 == Defensor) //Aggressor is more aggressive, so the outcome is more obvious
            return true;
        else if (type2 == Aggressor && type1 == Defensor)
            return false;
        else
            return rawValue(type1) > rawValue(type2);
    }
}