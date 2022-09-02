package net.shared;

import net.shared.SendChallengeResult;

//TODO: Change the implementation on the server
enum ServerEvent
{
    GameStarted(match_id:Int, logPreamble:String); //Sent when a game with one of the players being the user starts. Signals the app to navigate to the game screen. One of the answers to AcceptDirectChallenge. Also follows the DirectChallengeSent event unless DirectChallengeDeclined was emitted.
    SpectationData(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to Spectate. All the match details required may be derived from the currentLog arg. Signals the app to navigate to the game screen. 
    FollowPlayerGameStarted(match_id:Int, followedPlayerLogin:String, logPreamble:String); //Sent when a player followed by the user starts a new game. Signals the app to navigate to the game screen. 
    
    GameIsOver(log:String); //Answer to GetGame: game has ended and now can be revisited
    GameIsOngoing(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to GetGame: game is in process. Player should either spectate or reconnect based on whether the log contains their login
    GameNotFound; //Answer to GetGame: no such game exists

    SendDirectChallengeResult(result:SendChallengeResult); //Answer to CreateDirectChallenge
    IncomingDirectChallenge(enemy:String, colour:String, startSecs:Int, bonusSecs:Int); //Invoked on recipient side by CreateDirectChallenge
    DirectChallengeDeclined(callee:String); //Recipient has declined the challenge
    DirectChallengeCancelled(callee:String); //Answer to accepting direct challenge: it was cancelled before the recipient answered //! TODO: new event, add logic to both server & client
    DirectChallengeCallerOffline(caller:String); //Answer to accepting direct challenge: caller went offline before the recipient answered //! TODO: new event, add logic to both server & client
    DirectChallengeCallerInGame(caller:String); //Answer to accepting direct challenge: caller joined a different game before the recipient answered //! TODO: new event, add logic to both server & client
    
    OpenChallengeInfo(serializedParams:String); //Answer to GetOpenChallenge when it exists with challenge parameters
    OpenChallengeHostPlaying(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to GetOpenChallenge: host already started a game
    OpenchallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist

    OneTimeLoginDetails(password:String); //One-time password for a guest mock account
    
    LoginResult(success:Bool); //Answer to Login. Was the login successful
    RegisterResult(success:Bool); //Answer to Register. Was the registration successful
    ReconnectionNeeded(match_id:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, currentLog:String); //Answer to Login. Login succeeded, but player has an unfinished live game

    Message(author:String, message:String); //New in-game player message
    SpectatorMessage(author:String, message:String); //New in-game spectator message
    //TODO: Make sure the server responds to Move and AddTime with TimeCorrection. Other TimeCorrection emissions may be removed
    TimeCorrection(whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //Signals to update the in-game timers. Significant game events (Move, Rollback, GameEnded) also contain the same data which should be processed in the exact same way
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>, whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //A move has been played. Sent both to opponent and to all of the spectators
    Rollback(plysToUndo:Int, whiteSeconds:Float, blackSeconds:Float, timestamp:Float); //Signal to undo a number of plys in a current game. Sent to both spectators and players
    GameEnded(winner_color:String, reason:String, whiteSecondsRemainder:Float, blackSecondsRemainder:Float); //Game over. Sent both to players and to all of the spectators

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

    SingleStudy(name:String, variantStr:String); //Answer to GetStudy
    StudyNotFound; //Answer to GetStudy
    StudyCreated(studyID:Int, studyName:String); //Answer to SetStudy with no overwriteID specified
    PlayerProfile(recentGamesStr:String, recentStudiesStr:String, hasMoreGames:Bool, hasMoreStudies:Bool); //Answer to GetPlayerProfile //TODO: add more params (stats)
    GamesList(listStr:String, hasNext:Bool); //Answer to GetPlayerGames
    StudiesList(listStr:String, hasNext:Bool); //Answer to GetPlayerStudies
    PlayerNotFound; //Answer to Spectate, GetPlayerProfile, GetPlayerGames and GetPlayerStudies: no such player exists
    PlayerOffline; //Answer to Spectate: no game to spectate with a requested player
    PlayerNotInGame; //Answer to Spectate: no game to spectate with a requested player

    OpenChallenges(data:Array<String>); //Answer to GetOpenChallenges
    CurrentGames(data:Array<{id:Int, currentLog:String}>); //Answer to GetCurrentGames

    DontReconnect; //Signal preventing the other sessions' attempts to reconnect after a new session was created
}