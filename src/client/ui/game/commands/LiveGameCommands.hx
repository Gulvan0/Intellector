package client.ui.game.commands;

import http.HttpError;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;

/** The user's actions as a player of a game, sent the way the game's kind requires **/
interface LiveGameCommands
{
    /** `position`: the one `ply` is made in **/
    public function move(ply:RawPly, position:Position, onFailed:HttpError->Void):Void;

    /** `abort`: the game ends without a result, as it may until both sides have moved **/
    public function resign(abort:Bool, onFailed:HttpError->Void):Void;
}
