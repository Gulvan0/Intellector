package net.shared;

import net.shared.TimeReservesData;
import net.shared.PieceColor;

enum ServerEvent
{
    GameStarted(gameID:Int, logPreamble:String); //Sent when a game with one of the players being the user starts. Signals the app to navigate to the game screen. One of the answers to AcceptDirectChallenge. Also follows the DirectChallengeSent event unless DirectChallengeDeclined was emitted.
    SpectationData(gameID:Int, timeData:Null<TimeReservesData>, currentLog:String); //Sent to a spectator joining the game. All the match details required may be derived from the currentLog arg. Signals the app to navigate to the game screen. 
    
    GameIsOver(log:String); //Answer to GetGame: game has ended and now can be revisited
    GameIsOngoing(timeData:Null<TimeReservesData>, currentLog:String); //Answer to GetGame: game is in process. Player should either spectate or reconnect based on whether the log contains their login
    GameNotFound; //Answer to GetGame: no such game exists

    CreateChallengeResult(result:SendChallengeResult);

    IncomingDirectChallenge(data:ChallengeData);
    DirectChallengeCancelled(id:Int);

    DirectChallengeDeclined(id:Int); //Recipient has declined the challenge. Its 'accepted' counterpart doesn't exist, instead, GameStarted is sent right away

    ChallengeCancelledByOwner; //Answer to AcceptChallenge: it was cancelled before the recipient answered
    ChallengeOwnerOffline(owner:String); //Answer to AcceptChallenge: caller went offline before the recipient answered
    ChallengeOwnerInGame(owner:String); //Answer to AcceptChallenge: caller joined a different game before the recipient answered
    
    OpenChallengeInfo(data:ChallengeData); //Answer to GetOpenChallenge when it exists with challenge parameters
    OpenChallengeHostPlaying(gameID:Int, timeData:Null<TimeReservesData>, currentLog:String); //Answer to GetOpenChallenge: the challenge has already been accepted by other player, the game is in progress
    OpenChallengeGameEnded(gameID:Int, log:String); //Answer to GetOpenChallenge: the challenge has already been accepted by other player and the corresponding game has already ended
    OpenChallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist
    
    LoginResult(result:SignInResult); //Answer to Login
    RegisterResult(result:SignInResult); //Answer to Register
    RestoreSessionResult(result:SessionRestorationResult); //Answer to RestoreSession

    InvalidMove; //Sent to the player who attempted to perform an invalid move
    Message(authorRef:String, message:String); //New in-game player message
    SpectatorMessage(authorRef:String, message:String); //New in-game spectator message
    TimeCorrection(timeData:TimeReservesData); //Signals to update the in-game timers. Significant game events (Move, Rollback, TimeAdded, GameEnded) also contain the same data which should be processed in the exact same way
    Move(fromI:Int, toI:Int, fromJ:Int, toJ:Int, morphInto:Null<PieceType>, timeData:Null<TimeReservesData>); //A move has been played. Sent both to opponent and to all of the spectators
    Rollback(plysToUndo:Int, timeData:Null<TimeReservesData>); //Signal to undo a number of plys in a current game. Sent to both spectators and players
    TimeAdded(receiver:PieceColor, timeData:TimeReservesData);
    GameEnded(outcome:Outcome, rematchPossible:Bool, remainingTimeMs:Null<Map<PieceColor, Int>>, newPersonalElo:Null<EloValue>); //Game over. Sent both to players and to all of the spectators

    PlayerDisconnected(color:PieceColor); //Sent to the players and the spectators when one of the players disconnects
    PlayerReconnected(color:PieceColor); //Sent to the players and the spectators when one of the players reconnects
    NewSpectator(ref:String); //Sent both to players and to all of the spectators when a new user starts spectating
    SpectatorLeft(ref:String); //Sent both to players and to all of the spectators when a user stops spectating

    DrawOffered(color:PieceColor);
    DrawCancelled(color:PieceColor);
    DrawAccepted(color:PieceColor);
    DrawDeclined(color:PieceColor);
    TakebackOffered(color:PieceColor);
    TakebackCancelled(color:PieceColor);
    TakebackAccepted(color:PieceColor);
    TakebackDeclined(color:PieceColor);

    SingleStudy(info:StudyInfo); //Answer to GetStudy
    StudyNotFound; //Answer to GetStudy
    StudyCreated(studyID:Int, info:StudyInfo); //Answer to CreateStudy
    MiniProfile(data:MiniProfileData); //Answer to GetPlayerProfile
    PlayerProfile(data:ProfileData); //Answer to GetPlayerProfile
    Games(games:Array<GameInfo>, hasNext:Bool); //Answer to GetGamesByLogin, GetOngoingGamesByLogin
    Studies(studies:Map<Int, StudyInfo>, hasNext:Bool); //Answer to GetStudiesByLogin

    FollowSuccess; //Answer to FollowPlayer: no current game to spectate, but the player will be notified when the followed player starts playing

    PlayerNotFound; //Answer to FollowPlayer, GetPlayerProfile, GetGamesByLogin, GetOngoingGamesByLogin and GetStudiesByLogin: no such player exists

    OpenChallenges(data:Array<ChallengeData>); //Answer to GetOpenChallenges
    CurrentGames(data:Array<GameInfo>); //Answer to GetCurrentGames
    RecentGames(data:Array<GameInfo>); //Answer to GetRecentGames
    MainMenuData(openChallenges:Array<ChallengeData>, currentGames:Array<GameInfo>, recentGames:Array<GameInfo>); //Answer to MainMenuEntered. Contains the data of all three events above
    MainMenuNewOpenChallenge(data:ChallengeData);
    MainMenuOpenChallengeRemoved(id:Int);
    MainMenuNewGame(data:GameInfo);
    MainMenuGameEnded(data:GameInfo);

    SessionToken(token:String);
    DontReconnect; //Signal preventing the other sessions' attempts to reconnect after a new session was created
}