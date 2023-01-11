package net.shared;

using StringTools;

enum EloValue
{
    None;
    Provisional(elo:Int);
    Normal(elo:Int);
}

function deserialize(str:String):EloValue 
{
    if (str == "n")
        return None;
    else if (str.startsWith("p"))
        return Provisional(Std.parseInt(str.substr(1)));
    else 
        return Normal(Std.parseInt(str));
}

function serialize(value:EloValue):String 
{
    switch value 
    {
        case None:
            return "n";
        case Provisional(elo):
            return "p" + elo;
        case Normal(elo):
            return Std.string(elo);
    }
}