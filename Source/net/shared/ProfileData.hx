package net.shared;

class ProfileData
{
    public var elo:Map<TimeControlType, EloValue>;
    public var status:UserStatus;
    public var roles:Array<UserRole>;
    public var isFriend:Bool;
    public var friends:Array<FriendData>;
    public var preloadedGames:Array<GameInfo>;
    public var preloadedStudies:Map<Int, StudyInfo>;
    public var gamesInProgress:Array<GameInfo>;
    public var totalPastGames:Int;
    public var totalStudies:Int;
    public var gamesCntByTimeControl:Map<TimeControlType, Int>;

    public function findMainELO():EloValue
    {
        var argmax:TimeControlType = null;
        var max:Int = -1;

        for (tc => gamesCnt in gamesCntByTimeControl.keyValueIterator())
            if (gamesCnt > max || (gamesCnt == max && isSecondLongerThanFirst(argmax, tc)))
            {
                argmax = tc;
                max = gamesCnt;
            }
            
        return elo.get(argmax);
    }

    public function new()
    {

    }
}