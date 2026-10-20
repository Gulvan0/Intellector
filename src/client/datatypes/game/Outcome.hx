package client.datatypes.game;

import intellectorboard.primitives.piece.PieceColor;

enum DecisiveOutcomeKind
{
    Mate;
    Breakthrough;
    Timeout;
    Resign;
    Abandon;
    /** Ended by the moderation, the cheater losing **/
    CheatingAbort;
}

enum DrawishOutcomeKind
{
    DrawAgreement;
    Repetition;
    NoProgress;
    Abort;
}

enum Outcome
{
    Decisive(kind:DecisiveOutcomeKind, winner:PieceColor);
    Drawish(kind:DrawishOutcomeKind);
}
