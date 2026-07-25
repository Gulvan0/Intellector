package client.datatypes;

import intellectorboard.primitives.piece.PieceColor;

enum DecisiveOutcomeKind
{
    Mate;
    Breakthrough;
    Timeout;
    Resign;
    Abandon;
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
