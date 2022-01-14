package net;

//! under_score -> PascalCase
enum ClientEvent
{
    Login(login:String, password:String);
    Register(login:String, password:String);
    CreateDirectChallenge(calleeLogin:String, secsStart:Int, secsBonus:Int, color:Null<String>); //! Callout -> CreateDirectChallenge; removed caller_login
    AcceptDirectChallenge(callerLogin:String); //! AcceptChallenge -> AcceptDirectChallenge; removed callee_login; Forwarded caller_login
    DeclineDirectChallenge(callerLogin:String); //! DeclineChallenge -> DeclineDirectChallenge; removed callee_login; Forwarded caller_login
    CancelDirectChallenge(calleeLogin:String); //! CancelCallout -> CancelDirectChallenge; Forwarded callee_login
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>); //! removed issuer_login
    RequestTimeoutCheck; //! removed issuer_login; eliminated $data
    Message(text:String); //! removed issuer_login; Forwarded text
    GetGame(id:Int); //! forwarded id 
    GetOpenChallenge(hostLogin:String); //! GetChallenge -> GetOpenChallenge; challenger -> host_login; Forwarded host_login
    CreateOpenChallenge(secsStart:Int, secsBonus:Int, color:Null<String>); //! OpenCallout -> CreateOpenChallenge; removed caller_login
    AcceptOpenChallenge(callerLogin:String); //! removed callee_login; Forwarded caller_login
    CancelOpenChallenge; //! CancelOpenCallout -> CancelOpenChallenge; removed caller_login; eliminated $data
    Spectate(watchedLogin:String); //! forwarded watched_login
    StopSpectate; //! eliminated $data
    Resign; //! eliminated $data
    DrawOffer; //! eliminated $data
    DrawCancel; //! eliminated $data
    DrawAccept; //! eliminated $data
    DrawDecline; //! eliminated $data
    TakebackOffer; //! eliminated $data
    TakebackCancel; //! eliminated $data
    TakebackAccept; //! eliminated $data
    TakebackDecline; //! eliminated $data
    GetPlayerGames(login:String, after:Int, pageSize:Int);
    GetPlayerStudies(login:String, after:Int, pageSize:Int);
    SetStudy(name:String, variantStr:String, startingSIP:String, overwriteID:Null<Int>);
    DoesPlayerExist(login:String); //! forwarded login
    AddTime; //! eliminated $data
}