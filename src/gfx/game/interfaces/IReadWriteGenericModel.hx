package gfx.game.interfaces;

import net.shared.PieceColor;

interface IReadWriteGenericModel extends IReadOnlyGenericModel
{
    public var shownMovePointer:Int;
    public var orientation:PieceColor;
    public var boardInteractivityMode:InteractivityMode;    
}