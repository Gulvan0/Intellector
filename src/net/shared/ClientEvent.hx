package net.shared;

import net.shared.dataobj.*;
import net.shared.board.RawPly;

enum ClientEvent
{
    Greet(greeting:Greeting, clientBuild:Int, minServerBuild:Int);
    Login(login:String, password:String);
    Register(login:String, password:String);
    LogOut;
    CreateChallenge(params:ChallengeParams);
    CancelChallenge(challengeID:Int);
    AcceptChallenge(challengeID:Int); 
    DeclineDirectChallenge(challengeID:Int);
    Move(ply:RawPly); 
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
    PageUpdated(page:ViewedScreen);
    KeepAliveBeat;
    ResendRequest(from:Int, to:Int);
    MissedEvents(map:Map<Int, ClientEvent>);
}