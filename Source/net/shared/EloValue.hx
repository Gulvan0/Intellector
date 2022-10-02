package net.shared;

enum EloValue
{
    None;
    Provisional(elo:Int);
    Normal(elo:Int);
}