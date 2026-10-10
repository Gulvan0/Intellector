package client.datatypes;

/** The order of the ongoing games widget's sections, both with the games on the user's move first **/
class OngoingGameOrdering
{
    /** Timed games, least remaining time of the user's at the top of each group **/
    public static function timed(games:Array<OngoingGame>, nowMs:Float):Array<OngoingGame>
    {
        return ordered(games, game -> game.clock != null ? game.clock.remainingMs(game.ownColor, nowMs) : 0);
    }

    /** Correspondence games, the one waiting the longest at the top of each group **/
    public static function correspondence(games:Array<OngoingGame>):Array<OngoingGame>
    {
        return ordered(games, game -> game.waitingSinceMs());
    }

    private static function ordered(games:Array<OngoingGame>, key:OngoingGame->Float):Array<OngoingGame>
    {
        var result:Array<OngoingGame> = games.copy();
        result.sort((a, b) -> {
            if (a.isOwnMove() != b.isOwnMove())
                return a.isOwnMove() ? -1 : 1;
            var byKey:Int = Reflect.compare(key(a), key(b));
            return byKey != 0 ? byKey : a.id - b.id;
        });
        return result;
    }
}
