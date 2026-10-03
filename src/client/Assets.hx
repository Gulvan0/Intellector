package client;

import intellectorboard.primitives.piece.PieceKind;
import intellectorboard.primitives.piece.PieceColor;

class Assets
{
    public static function menuItemIcon(name:String):String
    {
        return 'assets/images/menubar/menu_items/$name.svg';
    }

    public static function pieceImage(kind:PieceKind, color:PieceColor):String
    {
        return 'assets/images/common/board/pieces/${kind}_${color}.svg';
    }

    /*
        Each piece kind's own SVG asset has a fixed aspect ratio (width/height of its own viewBox),
        close enough between the white/black variants of the same kind to treat as one constant -
        the couple-percent difference between color variants isn't visually distinguishable.
    */
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
}
