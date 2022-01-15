package gameboard.states;

import struct.IntPoint;
import struct.Hex;
import net.ServerEvent;

class PlayerMoveSelectedState extends BaseSelectedState
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

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new PlayerMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, cursorLocation);
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

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.playerColor = playerColor;
    }
}