package struct;

import struct.PieceColor;

enum Outcome
{
    Mate(winner:PieceColor);
    Breakthrough(winner:PieceColor);
    Timeout(winner:PieceColor);
    Resign(winner:PieceColor);
    Abandon(winner:PieceColor);
    DrawAgreement;
    Repetition;
    NoProgress;
    Abort;
}

function isDrawish(outcome:Outcome)
{
    switch outcome 
    {
        case Mate(_), Breakthrough(_), Timeout(_), Resign(_), Abandon(_):
            return false;
        case DrawAgreement, Repetition, NoProgress, Abort:
            return true;
    }
}