package net;

//TODO: Change the implementation on the server
enum ServerEvent
{
    GameStarted(match_id:Int, enemy:String, colour:String, startSecs:Int, bonusSecs:Int); //Called when the game featuring player starts. Signals to draw the gameboard. One of the answers to AcceptDirectChallenge. Also follows the DirectChallengeSent event unless DirectChallengeDeclined was emitted.
    SpectationData(match_id:Int, whiteLogin:String, blackLogin:String, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String, currentLog:String); //Answer to Spectate. All the match details required
    
    PlayerExistanceAnswer(exists:Bool); //Answer to DoesPlayerExist
    GameIsOver(log:String); //Answer to GetGame: game has ended and now can be revisited
    GameIsOngoing(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String, currentLog:String); //Answer to GetGame: game is in process. Player should either spectate or reconnect based on whether the log contains their login
    GameNotFound; //Answer to GetGame: no such game exists

    DirectChallengeCalleeIsCaller(callee:String); //Answer to CreateDirectChallenge: a player has tried to challenge themselves
    DirectChallengeCalleeOffline(callee:String); //Answer to CreateDirectChallenge: recipient is offline //! TODO: new event, add logic to both server & client
    DirectChallengeCalleeNotFound(callee:String); //Answer to CreateDirectChallenge: there is no such player as recipient
    DirectChallengeCalleeInGame(callee:String); //Answer to CreateDirectChallenge: recipient is offline
    DirectChallengeRepeated(callee:String); //Answer to CreateDirectChallenge: the challenge to this recipient has already been sent
    DirectChallengeSent(callee:String); //Answer to CreateDirectChallenge: direct challenge is sent successfully
    IncomingDirectChallenge(enemy:String, colour:String, startSecs:Int, bonusSecs:Int); //Invoked on recipient side by CreateDirectChallenge
    DirectChallengeDeclined(callee:String); //Answer to CreateDirectChallenge: recipient has declined the challenge
    DirectChallengeWasCancelled(callee:String); //Answer to accepting direct challenge: it was cancelled before the recipient answered //! TODO: new event, add logic to both server & client
    DirectChallengeCallerOffline(caller:String); //Answer to accepting direct challenge: caller went offline before the recipient answered //! TODO: new event, add logic to both server & client
    DirectChallengeCallerInGame(caller:String); //Answer to accepting direct challenge: caller joined a different game before the recipient answered //! TODO: new event, add logic to both server & client
    
    OpenChallengeInfo(hostLogin:String, secsStart:Int, secsBonus:Int, color:Null<String>); //Answer to GetOpenChallenge when it exists with challenge details
    OpenchallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist
    OneTimeLoginDetails(password:String); //One-time password for a guest mock account
    
    LoginResult(success:Bool); //Answer to Login. Was the login successful
    RegisterResult(success:Bool); //Answer to Register. Was the registration successful
    ReconnectionNeeded(match_id:Int, whiteLogin:String, blackLogin:String, whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String, currentLog:String); //Answer to Login. Login succeeded, but player has an unfinished live game

    Message(message:String); //New in-game player message
    SpectatorMessage(message:String); //New in-game spectator message
    TimeCorrection(whiteSeconds:Float, blackSeconds:Float, timestamp:Float, pingSubtractionSide:String); //Signals to update the in-game timers
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<String>); //A move has been played. Sent both to opponent and to all of the spectators
    Rollback(plysToUndo:Int); //Signal to undo a number of plys in a current game. Sent to both spectators and players
    GameEnded(winner_color:String, reason:String); //Game over. Sent both to players and to all of the spectators

    PlayerDisconnected(color:String); //Sent to the players and the spectators when one of the players disconnects
    PlayerReconnected(color:String); //Sent to the players and the spectators when one of the players reconnects
    NewSpectator(login:String); //Sent both to players and to all of the spectators when a new user starts spectating
    SpectatorLeft(login:String); //Sent both to players and to all of the spectators when a user stops spectating

    GamesList(listStr:String, hasNext:Bool, hasPrev:Bool); //Answer to GetPlayerGames
    StudiesList(listStr:String, hasNext:Bool, hasPrev:Bool); //Answer to GetPlayerStudies
    PlayerNotFound; //Answer to Spectate, GetPlayerGames and GetPlayerStudies: no such player exists
    PlayerNotInGame; //Answer to Spectate: no game to spectate with a requested player

    DontReconnect; //Signal preventing the other sessions' attempts to reconnect after a new session was created
}