package gfx.utils;

import haxe.ui.util.Color;
import gameboard.util.HexagonSelectionState;

class Colors
{
    public static var border:Color = 0x664126;
    public static var arrow:Color = 0xFF0000;

    public static var variantTreeBackground:Color = 0xEEEEEE;
    public static var variantTreeUnselectedArrow:Color = 0x333333;
    public static var variantTreeSelectedArrow:Color = 0xFF0000;

    public static function hexFill(selectionState:HexagonSelectionState, isDark:Bool):Color
    {
        return switch selectionState
        {
            case Normal: isDark? 0xd18b47 : 0xffcf9f; 
            case LMB, StrongHover: 0xe56000;
            case PaleHover: isDark? 0xd1a171 : 0xffe8d1;
            case LastMove: isDark? 0xBE9C26 : 0xFDD340;
            case RMB: isDark? 0xBE3726 : 0xFF6955;
            case Premove: isDark? 0x648039 : 0x869E60;
        }
    }

    public static function hexRowNumber(isDark:Bool):Color 
    {
        return isDark? 0xFFD8B2 : 0x664126;
    }
}
