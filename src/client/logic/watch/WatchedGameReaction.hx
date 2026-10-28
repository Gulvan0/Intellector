package client.logic.watch;

import client.datatypes.watch.WatchedGameOpening;
import client.datatypes.watch.WatchedGameReactionKind;

/** Whether a game started by the watched player opens at once or is announced **/
class WatchedGameReaction
{
    /**
        `pageMayBeLeft`: the open page doesn't refuse leaving. `playingTimedGame` / `spectatingTimedGame`:
        the open page shows an unfinished timed game the user plays / doesn't play.
    **/
    public static function decide(opening:WatchedGameOpening, pageMayBeLeft:Bool, playingTimedGame:Bool, spectatingTimedGame:Bool):WatchedGameReactionKind
    {
        if (!pageMayBeLeft || playingTimedGame)
            return Announce;

        return switch opening {
            case ALWAYS: Navigate;
            case UNLESS_SPECTATING: spectatingTimedGame ? Announce : Navigate;
            case NEVER: Announce;
        }
    }
}
