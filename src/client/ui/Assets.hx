package client.ui;

import client.datatypes.timecontrol.TimeControlKind;
import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.piece.PieceColor;

class Assets
{
    public static function menuItemIcon(name:String):String
    {
        return 'assets/images/menubar/menu_items/$name.svg';
    }

    public static function timeControlKindIcon(kind:TimeControlKind):String
    {
        return 'assets/images/common/time_controls/${kind.getName().toLowerCase()}.svg';
    }

    public static function colorIcon(color:Null<PieceColor>):String
    {
        var name:String = color != null? color.getName().toLowerCase() : "both";
        return 'assets/images/common/piece_color_indicators/$name.svg';
    }

    /** An icon of the shared controls: dropdowns, checkboxes, pagers **/
    public static function controlIcon(name:String):String
    {
        return 'assets/images/common/controls/$name.svg';
    }

    public static function profileIcon(name:String):String
    {
        return 'assets/images/profile/$name.svg';
    }

    public static function analysisIcon(name:String):String
    {
        return 'assets/images/analysis/$name.svg';
    }

    public static function pieceImage(kind:PieceKind, color:PieceColor):String
    {
        return 'assets/images/common/board/pieces/${kind}_${color}.svg';
    }

    public static function pieceAspectRatio(kind:PieceKind):Float
    {
        return switch kind {
            case Progressor: 1.08887;
            case Aggressor: 0.66371;
            case Dominator: 0.66793;
            case Liberator: 0.79958;
            case Defensor: 0.65379;
            case Intellector: 0.62913;
        }
    }

    /** A piece's art height relative to the Intellector's, as the board draws it **/
    public static function pieceRelativeScale(kind:PieceKind):Float
    {
        return switch kind {
            case Progressor: StyleVars.BOARD_PROGRESSOR_SCALE;
            case Liberator: StyleVars.BOARD_LIBERATOR_SCALE;
            case Defensor: StyleVars.BOARD_DEFENSOR_SCALE;
            default: 1;
        }
    }
}
