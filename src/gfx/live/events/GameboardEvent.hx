package gfx.live.events;

import net.shared.board.Hex;
import gfx.live.events.util.MoveIntentOptions;
import net.shared.board.HexCoords;

enum GameboardEvent 
{
    MoveAttempted(from:HexCoords, to:HexCoords, options:MoveIntentOptions);
    HexSelected(coords:HexCoords);
    LMBPressed(hexUnderCursor:Hex);
}