package gfx.profile.data;

import net.shared.EloValue;
import net.shared.OverviewGameData;
import net.shared.StudyInfo;
import net.shared.UserRole;
import net.shared.TimeControlType;

class ProfileData
{
    public var elo:Map<TimeControlType, EloValue>;
    public var status:UserStatus;
    public var roles:Array<UserRole>;
    public var isFriend:Bool;
    public var friends:Array<FriendData>;
    public var preloadedGames:Array<OverviewGameData>;
    public var preloadedStudies:Array<StudyInfo>;
    public var gamesInProgress:Array<OverviewGameData>;
    public var totalPastGames:Int;
    public var totalStudies:Int;
    public var gamesCntByTimeControl:Map<TimeControlType, Int>;

    public static function deserialize(s:String):ProfileData
    {
        throw "Not implemented";
    }

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