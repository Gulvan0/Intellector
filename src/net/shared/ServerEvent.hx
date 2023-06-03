package net.shared;

import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.*;
import net.shared.board.RawPly;

enum ServerEvent
{
    GreetingResponse(data:GreetingResponseData); //Answer to Greeting

    GoToGame(data:GameModelData); //Signals the app to open the game screen. Depending on whether the user is a participant, it may either be a MatchVersusPlayer or a Spectation screen
    
    GameRetrieved(data:GameModelData); //Answer to GetGame
    GameNotFound; //Answer to GetGame when no such game exists

    CreateChallengeResult(result:SendChallengeResult);

    IncomingDirectChallenge(data:ChallengeData);
    DirectChallengeCancelled(id:Int);

    DirectChallengeDeclined(id:Int); //Recipient has declined the challenge. Its 'accepted' counterpart doesn't exist, instead, GoToGame is sent right away

    ChallengeCancelledByOwner; //Answer to AcceptChallenge: it was cancelled before the recipient answered
    ChallengeOwnerOffline(owner:String); //Answer to AcceptChallenge: caller went offline before the recipient answered
    ChallengeOwnerInGame(owner:String); //Answer to AcceptChallenge: caller joined a different game before the recipient answered
    ChallengeNotAcceptedServerShutdown; //Answer to AcceptChallenge: can't accept a challenge, server is shutting down
    
    OpenChallengeInfo(data:ChallengeData); //Answer to GetOpenChallenge when it exists with challenge parameters
    OpenChallengeAlreadyAccepted(data:GameModelData); //Answer to GetOpenChallenge: the challenge has already been accepted by other player
    OpenChallengeCancelled; //Answer to GetOpenChallenge when it doesn't exist
    OpenChallengeNotFound; //Answer to GetOpenChallenge when it doesn't exist
    
    LoginResult(result:SignInResult); //Answer to Login
    RegisterResult(result:RegisterResult); //Answer to Register

    MoveAccepted(timeData:Null<TimeReservesData>); //timeData is only null in correspondence games
    InvalidMove; //Sent to the player who attempted to perform an invalid move
    Message(authorRef:String, message:String); //New in-game player message
    SpectatorMessage(authorRef:String, message:String); //New in-game spectator message
    Move(ply:RawPly, timeData:Null<TimeReservesData>); //A move has been played. Sent both to opponent and to all of the spectators. timeData is only null in correspondence games
    Rollback(plysToUndo:Int, updatedTimestamp:Null<UnixTimestamp>); //Signal to undo a number of plys in a current game. Sent to both spectators and players. updatedTimestamp is only null in correspondence games
    TimeAdded(receiver:PieceColor, timeData:TimeReservesData); //A player has added some time to their opponent. timeData can't be null since this event isn't dispatched in correspondence games
    GameEnded(outcome:Outcome, timeData:Null<TimeReservesData>, newPersonalElo:Null<EloValue>); //Game over. Sent both to players and to all of the spectators

    PlayerDisconnected(color:PieceColor); //Sent to the players and the spectators when one of the players disconnects
    PlayerReconnected(color:PieceColor); //Sent to the players and the spectators when one of the players reconnects
    NewSpectator(ref:String); //Sent both to players and to all of the spectators when a new user starts spectating
    SpectatorLeft(ref:String); //Sent both to players and to all of the spectators when a user stops spectating

    OfferActionPerformed(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction);

    SingleStudy(info:StudyInfo); //Answer to GetStudy
    StudyNotFound; //Answer to GetStudy
    StudyCreated(info:StudyInfo); //Answer to CreateStudy
    MiniProfile(data:MiniProfileData); //Answer to GetPlayerProfile
    PlayerProfile(data:ProfileData); //Answer to GetPlayerProfile
    Games(games:Array<GameInfo>, hasNext:Bool); //Answer to GetGamesByLogin, GetOngoingGamesByLogin
    Studies(studies:Array<StudyInfo>, hasNext:Bool); //Answer to GetStudiesByLogin

    FollowAlreadySpectating(id:Int); //Answer to FollowPlayer: added to follower list, but the game is already viewed by client
    FollowSuccess; //Answer to FollowPlayer: no current game to spectate, but the player will be notified when the followed player starts playing

    PlayerNotFound; //Answer to FollowPlayer, GetPlayerProfile, GetGamesByLogin, GetOngoingGamesByLogin and GetStudiesByLogin: no such player exists

    OpenChallenges(data:Array<ChallengeData>); //Answer to GetOpenChallenges
    CurrentGames(data:Array<GameInfo>); //Answer to GetCurrentGames
    RecentGames(data:Array<GameInfo>); //Answer to GetRecentGames
    MainMenuData(openChallenges:Array<ChallengeData>, currentGames:Array<GameInfo>, recentGames:Array<GameInfo>); //Answer to PageUpdated(MainMenu). Contains the data of all three events above
    MainMenuNewOpenChallenge(data:ChallengeData);
    MainMenuOpenChallengeRemoved(id:Int);
    MainMenuNewGame(data:GameInfo);
    MainMenuGameEnded(data:GameInfo);

    DontReconnect; //Signal preventing the other sessions' attempts to reconnect after a new session was created
    ServerError(message:String); //An error occured while processing the event on the server-side

    KeepAliveBeat; //Notify that the connection is still active
    ResendRequest(from:Int, to:Int); //Ask client to resend messages with ids between from and to inclusively
    MissedEvents(map:Map<Int, ServerEvent>); //Resend events missed by client
}