package tests.data;

import net.shared.dataobj.FriendData;
import net.shared.dataobj.MiniProfileData;
import net.shared.dataobj.ProfileData;

class ProfileInfos
{
    public static function friendList1():Array<FriendData>
    {
        return [
            {login: "gulvan", status: Online},
            {login: "kazvixx", status: Offline(20)},
            {login: "kartoved", status: Offline(123456)},
            {login: "superqwerty", status: InGame},
            {login: "kaz", status: Offline(12345678)}
        ];
    }

    public static function data1():ProfileData
    {
        var data:ProfileData = new ProfileData();

        data.gamesCntByTimeControl = [
            Hyperbullet => 0,
            Bullet => 20,
            Blitz => 3,
            Rapid => 228,
            Classic => 0,
            Correspondence => 1
        ];
        data.elo = [
            Hyperbullet => None,
            Bullet => Normal(1123),
            Blitz => Provisional(1964),
            Rapid => Normal(1556),
            Classic => None,
            Correspondence => Provisional(1520)
        ]; 
        data.isFriend = false;
        data.status = Offline(12345678);
        data.roles = [Admin];
        data.friends = friendList1();
        data.preloadedGames = [];
        data.preloadedStudies = [];
        data.gamesInProgress = [];
        data.totalPastGames = 252;
        data.totalStudies = 0;
        
        return data;
    }

    public static function miniData1():MiniProfileData
    {
        var data:MiniProfileData = new MiniProfileData();

        data.gamesCntByTimeControl = [
            Hyperbullet => 0,
            Bullet => 20,
            Blitz => 3,
            Rapid => 228,
            Classic => 0,
            Correspondence => 1
        ];
        data.elo = [
            Hyperbullet => None,
            Bullet => Normal(1123),
            Blitz => Provisional(1964),
            Rapid => Normal(1556),
            Classic => None,
            Correspondence => Provisional(1520)
        ]; 
        data.isFriend = false;
        data.status = InGame;

        return data;
    }
}