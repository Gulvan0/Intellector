package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;

/** A line of the game's chat: a player's message or a note about what happened in the game **/
enum GameChatEntry
{
    Message(message:GameChatMessage);
    Offer(action:OfferAction, kind:OfferKind, author:PieceColor);
    TimeAdded(receiver:PieceColor, amountSeconds:Int);
    Ended(outcome:Outcome);
}
