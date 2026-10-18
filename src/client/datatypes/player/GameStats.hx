package client.datatypes.player;

class GameStats
{
    /** One per time control kind, in `TimeControlKind`'s order **/
    public final kinds:Array<KindStats>;
    public final mainRating:Null<MainRating>;

    public function new(kinds:Array<KindStats>, mainRating:Null<MainRating>)
    {
        this.kinds = kinds;
        this.mainRating = mainRating;
    }

    public function hasGames():Bool
    {
        return Lambda.exists(kinds, stats -> stats.totalGames > 0);
    }

    public function ratedKinds():Array<KindStats>
    {
        return kinds.filter(stats -> stats.hasRating());
    }
}
