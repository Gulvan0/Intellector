package client.ui.game.controllers;

import client.datatypes.game.LiveGameState;
import client.datatypes.game.PlyHistory;
import client.ui.game.commands.ExternalGameCommands;
import client.ui.game.commands.InternalGameCommands;
import client.ui.game.commands.LiveGameCommands;
import intellectorboard.primitives.piece.PieceColor;

/** What the controllers of an open game share: its state, and the user's part in it **/
class LiveGameSession
{
    public final gameId:Int;
    public final state:LiveGameState;

    /** Null if the user doesn't play this game **/
    public var userColor:Null<PieceColor>;
    /** The color at the bottom of the board **/
    public var orientation:PieceColor;

    public function new(gameId:Int, state:LiveGameState, userColor:Null<PieceColor>)
    {
        this.gameId = gameId;
        this.state = state;
        this.userColor = userColor;
        this.orientation = userColor ?? White;
    }

    public function isPlaying():Bool
    {
        return userColor != null && !state.isOver() && (!state.info.isExternal() || state.info.bot != null);
    }

    public function followsLatestMove():Bool
    {
        return PlyHistory.followsLatestMove(Preferences.followLatestMove.get(), isPlaying());
    }

    public function commands():LiveGameCommands
    {
        return state.info.isExternal() ? new ExternalGameCommands(gameId, userColor) : new InternalGameCommands(gameId);
    }
}
