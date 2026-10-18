package client.datatypes.game;

import client.datatypes.timecontrol.TimeControlKind;

/**
    How many games each option of a game filter's facets would match. Each facet's counts apply the
    other facets, but not itself.
**/
class GameCounts
{
    private final byKind:Map<TimeControlKind, Int>;
    public final rated:Int;
    public final casual:Int;

    public function new(byKind:Map<TimeControlKind, Int>, rated:Int, casual:Int)
    {
        this.byKind = byKind;
        this.rated = rated;
        this.casual = casual;
    }

    public function ofKind(kind:TimeControlKind):Int
    {
        return byKind.get(kind) ?? 0;
    }
}
