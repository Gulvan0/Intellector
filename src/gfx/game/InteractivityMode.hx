package gfx.game;

import haxe.ds.ReadOnlyArray;
import net.shared.board.Hex;
import net.shared.board.HexCoords;
import net.shared.PieceColor;

enum InteractivityMode 
{
    PlySelection(getAllowedDestinations:HexCoords->Array<HexCoords>);
    HexSelection(isSelectable:HexCoords->Bool);
    FreeMove(canBeMoved:HexCoords->Bool);
    NotInteractive;    
}