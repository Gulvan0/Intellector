package client.datatypes.games;

import client.datatypes.bot.BotKind;

/** Which bots a player value matches **/
enum BotFilter
{
    AnyBot;
    Anaconda;
    AnyLevel(kind:BotKind);
    Level(kind:BotKind, level:Int);
}
