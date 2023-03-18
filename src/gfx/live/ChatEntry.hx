package gfx.live;

import dict.Phrase;
import net.shared.utils.PlayerRef;

enum ChatEntry 
{
    Message(playerRef:PlayerRef, messageText:String);
    Log(phrase:Phrase);
}