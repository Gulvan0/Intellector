package net.shared.message;

import net.shared.dataobj.StudyInfo;
import net.shared.TimeControlType;
import net.shared.dataobj.ChallengeParams;

enum ClientRequest 
{
    Login(login:String, password:String);
    Register(login:String, password:String);

    GetGamesByLogin(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>);
    GetStudiesByLogin(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>);
    GetOngoingGamesByLogin(login:String);

    GetMainMenuData;

    GetOpenChallenges;
    GetCurrentGames;
    GetRecentGames;

    GetGame(id:Int);
    GetStudy(id:Int);
    GetOpenChallenge(id:Int); 

    GetMiniProfile(login:String);
    GetPlayerProfile(login:String);
    
    CreateChallenge(params:ChallengeParams);
    CreateStudy(info:StudyInfo);
    
    Subscribe(subscription:Subscription);
    Unsubscribe(subscription:Subscription);
}