package net.shared;

import net.shared.ProfileData;

enum ServerEvent
{
    GameStarted(match_id:Int, logPreamble:String); //Sent when a game with one of the players being the user starts. Signals the app to navigate to the game screen. One of the answers to AcceptDirectChallenge. Also follows the DirectChallengeSent event unless DirectChallengeDeclined was emitted.
    SpectationData(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to Spectate. All the match details required may be derived from the currentLog arg. Signals the app to navigate to the game screen. 
    
    GameIsOver(log:String); //Answer to GetGame: game has ended and now can be revisited
    GameIsOngoing(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to GetGame: game is in process. Player should either spectate or reconnect based on whether the log contains their login
    GameNotFound; //Answer to GetGame: no such game exists

    CreateChallengeResult(result:SendChallengeResult);

    IncomingDirectChallenge(id:Int, serializedParams:String);

    DirectChallengeDeclined(id:Int); //Recipient has declined the challenge. Its 'accepted' counterpart doesn't exist, instead, GameStarted is sent right away

    DirectChallengeCancelled(caller:String); //Answer to accepting direct challenge: it was cancelled before the recipient answered //TODO: Ensure this has lower priority than the following two
    DirectChallengeCallerOffline(caller:String); //Answer to accepting direct challenge: caller went offline before the recipient answered
    DirectChallengeCallerInGame(caller:String); //Answer to accepting direct challenge: caller joined a different game before the recipient answered
    
    OpenChallengeInfo(id:Int, serializedParams:String); //Answer to GetOpenChallenge when it exists with challenge parameters
    OpenChallengeHostPlaying(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to GetOpenChallenge: host already started a game //TODO: Keep track of challengeOwners, or else OpenchallengeNotFound will always be returned instead
    OpenchallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist
    
    LoginResult(result:SignInResult); //Answer to Login
    RegisterResult(result:SignInResult); //Answer to Register
    ReconnectionNeeded(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to Login. Login succeeded, but player has an unfinished live game

    Message(author:String, message:String); //New in-game player message
    SpectatorMessage(author:String, message:String); //New in-game spectator message
    //TODO: Make sure the server responds to Move and AddTime with TimeCorrection. Other TimeCorrection emissions may be removed
    TimeCorrection(whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //Signals to update the in-game timers. Significant game events (Move, Rollback, GameEnded) also contain the same data which should be processed in the exact same way
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>, whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //A move has been played. Sent both to opponent and to all of the spectators
    Rollback(plysToUndo:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //Signal to undo a number of plys in a current game. Sent to both spectators and players
    GameEnded(winner_color:String, reason:String, whiteSecondsRemainder:Float, blackSecondsRemainder:Float, newPersonalElo:Null<Int>); //Game over. Sent both to players and to all of the spectators

    PlayerDisconnected(color:String); //Sent to the players and the spectators when one of the players disconnects
    PlayerReconnected(color:String); //Sent to the players and the spectators when one of the players reconnects
    NewSpectator(login:String); //Sent both to players and to all of the spectators when a new user starts spectating
    SpectatorLeft(login:String); //Sent both to players and to all of the spectators when a user stops spectating

    DrawOffered;
    DrawCancelled;
    DrawAccepted;
    DrawDeclined;
    TakebackOffered;
    TakebackCancelled;
    TakebackAccepted;
    TakebackDeclined;

    SingleStudy(info:StudyInfo); //Answer to GetStudy
    StudyNotFound; //Answer to GetStudy
    StudyCreated(studyID:Int, info:StudyInfo); //Answer to CreateStudy
    MiniProfile(data:MiniProfileData); //Answer to GetPlayerProfile
    PlayerProfile(data:ProfileData); //Answer to GetPlayerProfile
    Games(games:Array<GameInfo>, hasNext:Bool); //Answer to GetGamesByLogin, GetOngoingGamesByLogin
    Studies(studies:Map<Int, StudyInfo>, hasNext:Bool); //Answer to GetStudiesByLogin

    PlayerNotFound; //Answer to Spectate, GetPlayerProfile, GetGamesByLogin, GetOngoingGamesByLogin and GetStudiesByLogin: no such player exists
    PlayerOffline; //Answer to Spectate: no game to spectate with a requested player
    PlayerNotInGame; //Answer to Spectate: no game to spectate with a requested player

    OpenChallenges(data:Array<OpenChallengeData>); //Answer to GetOpenChallenges
    CurrentGames(data:Array<{id:Int, currentLog:String}>); //Answer to GetCurrentGames

    DontReconnect; //Signal preventing the other sessions' attempts to reconnect after a new session was created
}