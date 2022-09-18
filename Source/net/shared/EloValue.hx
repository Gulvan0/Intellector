package net.shared;

import utils.SpecialChar;

enum EloValue
{
    None;
    Provisional(elo:Int);
    Normal(elo:Int);
}

function eloToStr(value:EloValue):String
{
    return switch value 
    {
        case None: LongDash;
        case Provisional(elo): '$elo?';
        case Normal(elo): '$elo';
    }
}