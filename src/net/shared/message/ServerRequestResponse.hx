package net.shared.message;

import net.shared.dataobj.*;

enum ServerRequestResponse
{
    GameRetrieved(data:GameModelData); //Answer to GetGame
    GameNotFound; //Answer to GetGame when no such game exists

    OpenChallengeInfo(data:ChallengeData); //Answer to GetOpenChallenge when it exists with challenge parameters
    OpenChallengeAlreadyAccepted(data:GameModelData); //Answer to GetOpenChallenge: the challenge has already been accepted by other player
    OpenChallengeCancelled; //Answer to GetOpenChallenge when it doesn't exist
    OpenChallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist

    CreateChallengeResult(result:SendChallengeResult); //Answer to CreateChallenge

    LoginResult(result:SignInResult); //Answer to Login
    RegisterResult(result:RegisterResult); //Answer to Register

    SingleStudy(info:StudyInfo); //Answer to GetStudy
    StudyNotFound; //Answer to GetStudy

    StudyCreated(info:StudyInfo); //Answer to CreateStudy

    GetMiniProfile(data:MiniProfileData); //Answer to GetPlayerProfile
    PlayerProfile(data:ProfileData); //Answer to GetPlayerProfile

    Games(games:Array<GameModelData>, hasNext:Bool); //Answer to GetGamesByLogin, GetOngoingGamesByLogin
    Studies(studies:Array<StudyInfo>, hasNext:Bool); //Answer to GetStudiesByLogin

    PlayerNotFound; //Answer to GetPlayerProfile, GetGamesByLogin, GetOngoingGamesByLogin and GetStudiesByLogin: no such player exists
    
    Subscribed(subscription:Subscription); //Answer to Subscribe
    NotSubscribed(subscription:Subscription, reason:SubscriptionFailureReason); //Answer to Subscribe

    OpenChallenges(data:Array<ChallengeData>); //Answer to GetOpenChallenges
    CurrentGames(data:Array<GameModelData>); //Answer to GetCurrentGames
    RecentGames(data:Array<GameModelData>); //Answer to GetRecentGames
    
    MainMenuData(openChallenges:Array<ChallengeData>, currentGames:Array<GameModelData>, recentGames:Array<GameModelData>); //Answer to GetMainMenuData

    Unsubscribed(subscription:Subscription); //Answer to Unsubscribe
    NotUnsubscribed(subscription:Subscription); //Answer to Unsubscribe
}