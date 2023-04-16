package gfx.live;

import dict.Phrase;
import net.shared.utils.PlayerRef;

enum ChatEntry 
{
    PlayerMessage(playerRef:PlayerRef, messageText:String);
    SpectatorMessage(playerRef:PlayerRef, messageText:String);
    Log(phrase:Phrase);
}