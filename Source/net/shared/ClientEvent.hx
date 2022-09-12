package net.shared;

enum ClientEvent
{
    Login(login:String, password:String);
    Register(login:String, password:String);
    LogOut;
    CreateChallenge(serializedParams:String);
    CancelChallenge(challengeID:Int);
    AcceptOpenChallenge(challengeID:Int, guestLogin:Null<String>, guestPassword:Null<String>); 
    AcceptDirectChallenge(challengeID:Int); 
    DeclineDirectChallenge(challengeID:Int);
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>); 
    RequestTimeoutCheck; 
    Message(text:String); 
    GetOpenChallenge(hostLogin:String); 
    FollowPlayer(login:String); //TODO: Ensure this also includes an effect of StopSpectating
    StopSpectating; //Used both to stop spectating a game AND to stop following a player
    Resign; 
    OfferDraw; 
    CancelDraw; 
    AcceptDraw; 
    DeclineDraw; 
    OfferTakeback; 
    CancelTakeback; 
    AcceptTakeback; 
    DeclineTakeback;
    SetStudy(name:String, description:String, keyPositionSIP:String, variantStr:String, publicity:StudyPublicity, overwriteID:Null<Int>);
    AddTime; 
    GetGame(id:Int); //TODO: Ensure this also includes an effect of StopSpectating IN CASE THIS IS AN ONGOING GAME
    GetStudy(id:Int);
    GetPlayerProfile(login:String);
    AddFriend(login:String);
    RemoveFriend(login:String);
    GetGamesByLogin(login:String, after:Int, pageSize:Int, filterByTimeControl:Null<TimeControlType>);
    GetStudiesByLogin(login:String, after:Int, pageSize:Int, filterByTags:Null<Array<String>>);
    GetOngoingGamesByLogin(login:String);
    GetOpenChallenges;
    GetCurrentGames;
}