package gfx.utils;

import gameboard.Hexagon.HexagonSelectionState;

class Colors
{
    public static var border:Int = 0x664126;
    public static var arrow:Int = 0x108D99;

    public static function hexFill(selectionState:HexagonSelectionState, isDark:Bool):Int
    {
        return switch selectionState
        {
            case Normal: isDark? 0xd18b47 : 0xffcf9f;
            case LMB, Hover: isDark? 0xd16700 : 0xff9730;
            case LastMove: isDark? 0xBE9C26 : 0xFDD340;
            case RMB: isDark? 0xBE3726 : 0xFF6955;
            case Premove: isDark? 0x648039 : 0x869E60;
        }
    }

    public static function hexRowNumber(isDark:Bool):Int 
    {
        return isDark? 0x664126 : 0xFFD8B2;
    }
}
