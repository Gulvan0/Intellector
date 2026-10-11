package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;

/** A game event, numbered by the server in order of occurrence **/
enum LiveGameEvent
{
    /** `clock`: both clocks right after the ply, null for a correspondence game **/
    Ply(eventIndex:Int, plyIndex:Int, ply:RawPly, clock:Null<GameClock>);
    ChatMessage(eventIndex:Int, message:GameChatMessage);
    Offer(eventIndex:Int, action:OfferAction, kind:OfferKind, author:PieceColor);
    TimeAdded(eventIndex:Int, receiver:PieceColor, clock:GameClock);
    Rollback(eventIndex:Int, plyCountAfter:Int, clock:Null<GameClock>);
}
