package gfx.profile;

import net.shared.OverviewGameData;
import net.shared.OverviewStudyData;
import net.shared.UserRole;
import net.shared.TimeControlType;

class ProfileData
{
    public var elo:Map<TimeControlType, Null<Int>>;
    public var status:UserStatus;
    public var roles:Array<UserRole>;
    public var isFriend:Bool;
    public var friends:Array<FriendData>;
    public var preloadedGames:Array<OverviewGameData>;
    public var preloadedStudies:Array<OverviewStudyData>;
    public var gamesInProgress:Array<OverviewGameData>;
    public var totalPastGames:Int;
    public var totalStudies:Int;

    public static function deserialize(s:String):ProfileData
    {
        throw "Not implemented";
    }

    public function getMainELO():Null<Int>
    {
        var maxElo:Null<Int> = null;

        for (rating in elo)
            if (maxElo == null)
                maxElo = rating;
            else if (rating != null && rating > maxElo)
                maxElo = rating;

        return maxElo;
    }

    public function new()
    {

    }
}