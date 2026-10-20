package client.datatypes.share;

import client.datatypes.game.GameEnding;
import client.datatypes.game.LiveGameInfo;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;

/** A game as it was when the share overlay opened **/
typedef SharedGame = {
    info:LiveGameInfo,
    plies:Array<RawPly>,
    /** `positions[k]`: the position after `k` plies, from the starting one to the latest **/
    positions:Array<Position>,
    ending:Null<GameEnding>
}
