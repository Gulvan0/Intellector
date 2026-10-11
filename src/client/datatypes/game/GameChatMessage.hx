package client.datatypes.game;

class GameChatMessage
{
    public final authorRef:String;
    public final authorNickname:String;
    public final text:String;
    /** Sent by someone not playing, or after the game ended **/
    public final spectator:Bool;

    public function new(authorRef:String, authorNickname:String, text:String, spectator:Bool)
    {
        this.authorRef = authorRef;
        this.authorNickname = authorNickname;
        this.text = text;
        this.spectator = spectator;
    }
}
