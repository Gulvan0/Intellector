package gfx.game.events;

import net.shared.board.Hex;
import gfx.game.events.util.MoveIntentOptions;
import net.shared.board.HexCoords;

enum GameboardEvent 
{
    MoveAttempted(from:HexCoords, to:HexCoords, options:MoveIntentOptions);
    HexSelected(coords:HexCoords);
    FreeMovePerformed(from:HexCoords, to:HexCoords);
    LMBPressed(hexUnderCursor:HexCoords);
}