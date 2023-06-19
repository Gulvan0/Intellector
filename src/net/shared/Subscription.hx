package net.shared;

import net.shared.PieceColor;
import net.shared.utils.PlayerRef;

enum Subscription 
{
    MainMenuUpdates;
    PlayerProfileUpdates(ownerLogin:String);
    Game(id:Int, viewpointPlayerColor:Null<PieceColor>);
    StartingGames(ref:PlayerRef);
}