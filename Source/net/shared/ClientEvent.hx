package net.shared;

enum ClientEvent
{
    Login(login:String, password:String);
    Register(login:String, password:String);
    RestoreSession(token:String);
    LogOut;
    CreateChallenge(serializedParams:String);
    CancelChallenge(challengeID:Int);
    AcceptChallenge(challengeID:Int); 
    DeclineDirectChallenge(challengeID:Int);
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<PieceType>); 
    RequestTimeoutCheck; 
    Message(text:String); 
    SimpleRematch;
    Resign; 
    OfferDraw; 
    CancelDraw; 
    AcceptDraw; 
    DeclineDraw; 
    OfferTakeback; 
    CancelTakeback; 
    AcceptTakeback; 
    DeclineTakeback;
    AddTime; 
    GetOpenChallenge(id:Int); 
    FollowPlayer(login:String);
    LeaveGame(id:Int);
    StopFollowing;
    CreateStudy(info:StudyInfo);
    OverwriteStudy(overwrittenStudyID:Int, info:StudyInfo);
    DeleteStudy(id:Int);
    GetGame(id:Int);
    GetStudy(id:Int);
    GetMiniProfile(login:String);
    GetPlayerProfile(login:String);
    AddFriend(login:String);
    RemoveFriend(login:String);
    GetGamesByLogin(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>);
    GetStudiesByLogin(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>);
    GetOngoingGamesByLogin(login:String);
    GetOpenChallenges;
    GetCurrentGames;
    GetRecentGames;
}