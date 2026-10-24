package client.datatypes.game;

import client.datatypes.timecontrol.TimeControlKind;

/**
    A games list's filter: the kinds picked (a game of any of them matches; none picked means any kind)
    and the rated status (null for any). With `liveByDefault`, no kind picked means every kind but
    correspondence instead.
**/
class GameListFilter
{
    public static final KINDS:Array<TimeControlKind> = TimeControlKind.createAll();

    public final liveByDefault:Bool;

    public var kinds:Array<TimeControlKind> = [];
    public var rated:Null<Bool> = null;

    public function new(liveByDefault:Bool)
    {
        this.liveByDefault = liveByDefault;
    }

    public function isDefault():Bool
    {
        return kinds.length == 0 && rated == null;
    }

    public function reset():Void
    {
        kinds = [];
        rated = null;
    }

    /** The kinds a search asks for, null for any **/
    public function queriedKinds():Null<Array<TimeControlKind>>
    {
        if (kinds.length > 0)
            return kinds.copy();
        if (liveByDefault)
            return KINDS.filter(kind -> kind != Correspondence);
        return null;
    }

    public function matches(kind:TimeControlKind, rated:Bool):Bool
    {
        return matchesKind(kind) && (this.rated == null || this.rated == rated);
    }

    /** How many of `games` each option of the filter's facets would match **/
    public function countsOf(games:Array<GameRecord>):GameCounts
    {
        var byKind:Map<TimeControlKind, Int> = [];
        var rated:Int = 0;
        var casual:Int = 0;
        for (game in games)
        {
            var kind:TimeControlKind = game.timeControl.getKind();
            if (this.rated == null || this.rated == game.rated)
                byKind.set(kind, (byKind.get(kind) ?? 0) + 1);
            if (matchesKind(kind))
            {
                if (game.rated)
                    rated++;
                else
                    casual++;
            }
        }
        return new GameCounts(byKind, rated, casual);
    }

    private function matchesKind(kind:TimeControlKind):Bool
    {
        var queried:Null<Array<TimeControlKind>> = queriedKinds();
        return queried == null || queried.contains(kind);
    }
}
