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
}
