package gameboard.states;

import struct.IntPoint;
import struct.Hex;
import net.ServerEvent;
import net.ClientEvent;

class PlayerMoveDraggingState extends BaseDraggingState
{
    private final playerColor:PieceColor;

    private override function getNeutralState():BaseNeutralState
    {
        return new PlayerMoveNeutralState(boardInstance, playerColor, cursorLocation);
    }

    public override function movePossible(from:IntPoint, to:IntPoint):Bool
    {
        return Rules.possible(from, to, boardInstance.currentSituation.get);
    }

    private override function onMoveChosen(ply:Ply)
    {
        AssetManager.playPlySound(ply, boardInstance.shownSituation);
        Networker.emitEvent(Move(ply.from.i, ply.to.i, ply.from.j, ply.to.j, ply.morphInto));
        boardInstance.makeMove(ply);
        if (Preferences.instance.premoveEnabled)
            boardInstance.state = new EnemyMoveNeutralState(boardInstance, playerColor, [], cursorLocation);
        else
            boardInstance.state = new EnemyMoveNonPremovableState(boardInstance, playerColor, cursorLocation);
    }

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new PlayerMoveSelectedState(boardInstance, selectedHexLocation, playerColor, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Rollback(plysToUndo):
                boardInstance.revertPlys(plysToUndo);
                
            case GameEnded(winner_color, reason):
                boardInstance.state = new SpectatorState(boardInstance, cursorLocation);
        }
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.playerColor = playerColor;
    }
}