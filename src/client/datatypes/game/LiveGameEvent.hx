package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.ply.RawPly;

/** A game event, numbered by the server **/
enum LiveGameEvent
{
    /**
        `clock`: both clocks right after the ply, null for a correspondence game. `occurredAtMs`: when the ply was
        made, null if not recorded. `sipAfter`: the position the server got; null in a snapshot, which needs no check.
    **/
    Ply(eventIndex:Int, plyIndex:Int, ply:RawPly, clock:Null<GameClock>, occurredAtMs:Null<Float>, sipAfter:Null<String>);
    ChatMessage(eventIndex:Int, message:GameChatMessage);
    Offer(eventIndex:Int, action:OfferAction, kind:OfferKind, author:PieceColor);
    TimeAdded(eventIndex:Int, receiver:PieceColor, amountSeconds:Int, clock:GameClock);
    /** `sip`: the position the game is back at; null in a snapshot, which needs no check **/
    Rollback(eventIndex:Int, plyCountAfter:Int, clock:Null<GameClock>, sip:Null<String>);
    /** `clock`: both clocks as changed by this, if they were **/
    Suspension(eventIndex:Int, suspended:Bool, clock:Null<GameClock>);
}
