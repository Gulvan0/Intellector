package net;

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
    AcceptOpenChallenge(callerLogin:String); 
    CancelOpenChallenge; 
    Spectate(watchedLogin:String); 
    StopSpectate; 
    Rematch; //TODO: new event, process accordingly
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
    GetGame(id:Int);
    GetStudy(id:Int);
    GetPlayerProfile(login:String);
    GetPlayerGames(login:String, after:Int, pageSize:Int);
    GetPlayerStudies(login:String, after:Int, pageSize:Int);
}