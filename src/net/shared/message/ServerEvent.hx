package net.shared.message;

import net.shared.utils.PlayerRef;
import net.shared.utils.UnixTimestamp;
import net.shared.dataobj.*;
import net.shared.board.RawPly;

enum ServerEvent
{
    GoToGame(data:GameModelData); //Signals the app to open the game screen (which may vary depending on the game model data)

    IncomingDirectChallenge(data:ChallengeData); //Incoming direct challenge has been received
    DirectChallengeCancelled(id:Int); //Incoming direct challenge was cancelled

    DirectChallengeDeclined(id:Int); //Recipient has declined the challenge. Its 'accepted' counterpart doesn't exist, instead, GoToGame is sent right away

    ChallengeCancelledByOwner; //Answer to AcceptChallenge: it was cancelled before the recipient answered
    ChallengeOwnerOffline(owner:String); //Answer to AcceptChallenge: caller went offline before the recipient answered
    ChallengeOwnerInGame(owner:String); //Answer to AcceptChallenge: caller joined a different game before the recipient answered
    ChallengeNotAcceptedServerShutdown; //Answer to AcceptChallenge: can't accept a challenge, server is shutting down

    MoveAccepted(timestamp:UnixTimestamp); //timeData is only null in correspondence games
    InvalidMove; //Sent to the player who attempted to perform an invalid move
    Message(authorRef:String, message:String); //New in-game player message
    SpectatorMessage(authorRef:String, message:String); //New in-game spectator message
    Move(ply:RawPly, timestamp:UnixTimestamp); //A move has been played. Sent both to opponent and to all of the spectators
    Rollback(plysToUndo:Int, timestamp:UnixTimestamp); //Signal to undo a number of plys in a current game. Sent to both spectators and players
    TimeAdded(receiver:PieceColor); //A player has added some time to their opponent
    GameEnded(outcome:Outcome, timestamp:UnixTimestamp, newPersonalElo:Null<EloValue>); //Game over. Sent both to players and to all of the spectators
    GameUserOnlineStatusChanged(user:PlayerRef, online:Bool); //Sent when a player/spectator dis/reconnects
    OfferActionPerformed(offerSentBy:PieceColor, offer:OfferKind, action:OfferAction); //A player created/cancelled/accepted/declined a draw/takeback offer
    
    MainMenuNewOpenChallenge(data:ChallengeData); //MainMenuUpdates subscription: new open challenge appeared
    MainMenuOpenChallengeRemoved(id:Int); //MainMenuUpdates subscription: an existing open challenge has been removed
    MainMenuNewGame(data:GameModelData); //MainMenuUpdates subscription: new current game appeared
    MainMenuGameEnded(data:GameModelData); //MainMenuUpdates subscription: one of the current games has ended

    ServerError(message:String); //An error occured while processing the event on the server-side
}