package gameboard_revamped.events;

import net.shared.board.HexCoords;

enum GameboardEvent 
{
    MoveAttempted(from:HexCoords, to:HexCoords);
    LMBPressed;
}