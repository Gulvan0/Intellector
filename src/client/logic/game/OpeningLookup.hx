package client.logic.game;

import client.openings.OpeningEntry;
import client.openings.OpeningTree;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;

class OpeningLookup
{
    /** The opening of a game from the default position: the last of `positions` that is a known one **/
    public static function find(positions:Array<Position>):Null<OpeningEntry>
    {
        var found:Null<OpeningEntry> = null;
        for (position in positions)
        {
            var entry:Null<OpeningEntry> = OpeningTree.openings.get(Sip.fromPosition(position));
            if (entry != null)
                found = entry;
        }
        return found;
    }
}
