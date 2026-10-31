package client.datatypes.bot;

/** Who a bot user ref stands for **/
enum BotIdentity
{
    Haxaconda(kind:BotKind, strength:Int);
    /** The bot of the games played before the Haxaconda family **/
    LegacyAnaconda;
    Unknown;
}
