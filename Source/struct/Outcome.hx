package struct;

import struct.PieceColor;

enum DecisiveOutcomeType
{
    Mate;
    Breakthrough;
    Timeout;
    Resign;
    Abandon;
}

enum DrawishOutcomeType
{
    DrawAgreement;
    Repetition;
    NoProgress;
    Abort;
}

enum PersonalOutcome
{
    Win(type:DecisiveOutcomeType);
    Loss(type:DecisiveOutcomeType);
    Draw(type:DrawishOutcomeType);
}

enum Outcome
{
    Decisive(type:DecisiveOutcomeType, winnerColor:PieceColor);
    Drawish(type:DrawishOutcomeType);
}

function toPersonal(outcome:Outcome, playerColor:PieceColor):PersonalOutcome
{
    switch outcome 
    {
        case Decisive(type, winnerColor):
            if (winnerColor == playerColor)
                return Win(type);
            else
                return Loss(type);
        case Drawish(type):
            return Draw(type);
    }
}