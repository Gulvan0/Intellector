package client.datatypes.bot;

/** Which bot plays and how hard it tries **/
class BotSettings
{
    public final kind:BotKind;
    /** 1 to 9, see `BotStrengthRules` **/
    public final strength:Int;
    /** Null if the bot thinks as long as it likes **/
    public final thinkCapSeconds:Null<Int>;

    public function new(kind:BotKind, strength:Int, thinkCapSeconds:Null<Int>)
    {
        this.kind = kind;
        this.strength = strength;
        this.thinkCapSeconds = thinkCapSeconds;
    }
}
