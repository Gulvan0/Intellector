package net.shared;

enum ClientEvent
{
    Login(login:String, password:String);
    Register(login:String, password:String);
    LogOut;
    CreateDirectChallenge(calleeLogin:String, secsStart:Int, secsBonus:Int, color:Null<String>); 
    AcceptDirectChallenge(callerLogin:String); 
    DeclineDirectChallenge(callerLogin:String); 
    CancelDirectChallenge(calleeLogin:String); 
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>); 
    RequestTimeoutCheck; 
    Message(text:String); 
    GetOpenChallenge(hostLogin:String); 
    CreateOpenChallenge(secsStart:Int, secsBonus:Int, color:Null<String>); 
    AcceptOpenChallenge(callerLogin:String, guestLogin:Null<String>, guestPassword:Null<String>); 
    CancelOpenChallenge; 
    FollowPlayer(login:String); //TODO: Ensure this also includes an effect of StopSpectating
    StopSpectating; //Used both to stop spectating a game AND to stop following a player
    Rematch;
    Resign; 
    OfferDraw; 
    CancelDraw; 
    AcceptDraw; 
    DeclineDraw; 
    OfferTakeback; 
    CancelTakeback; 
    AcceptTakeback; 
    DeclineTakeback;
    SetStudy(name:String, variantStr:String, overwriteID:Null<Int>);
    AddTime; 
    GetGame(id:Int); //TODO: Ensure this also includes an effect of StopSpectating IN CASE THIS IS AN ONGOING GAME
    GetStudy(id:Int);
    GetPlayerProfile(login:String);
    GetPlayerGames(login:String, after:Int, pageSize:Int);
    GetPlayerStudies(login:String, after:Int, pageSize:Int);
    GetOpenChallenges;
    GetCurrentGames;
}