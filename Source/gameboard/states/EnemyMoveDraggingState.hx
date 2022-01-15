package gameboard.states;

import struct.Hex;
import openfl.geom.Point;
import struct.IntPoint;
import net.ServerEvent;

class EnemyMoveDraggingState extends BaseDraggingState
{
    private final playerColor:PieceColor;
    private var premoves:Array<Ply>;

    private override function getNeutralState():BaseNeutralState
    {
        return new EnemyMoveNeutralState(boardInstance, playerColor, premoves, cursorLocation);
    }

    public override function movePossible(from:IntPoint, to:IntPoint):Bool
    {
        return Rules.possible(from, to, p -> Hex.empty());
    }

    private override function onMoveChosen(ply:Ply)
    {
        boardInstance.applyMoveTransposition(ply.toReversible());
        boardInstance.getHex(ply.from).showLayer(Premove);
        boardInstance.getHex(ply.to).showLayer(Premove);
        boardInstance.state = new EnemyMoveNeutralState(boardInstance, playerColor, premoves.concat([ply]), cursorLocation);
    }

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new EnemyMoveSelectedState(boardInstance, selectedHexLocation, playerColor, premoves, cursorLocation);
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(_, _, _, _, _), Rollback(_):
                abortMovePrematurely();
                boardInstance.state = getNeutralState();
                boardInstance.state.handleNetEvent(event);
            case GameEnded(winner_color, reason):
                abortMovePrematurely();
                boardInstance.state = new SpectatorState(boardInstance, cursorLocation);
        }
    }

    private function abortMovePrematurely()
    {
        boardInstance.getPiece(dragStartLocation).stopDrag();
        boardInstance.returnPieceToOriginalPosition(dragStartLocation);

        boardInstance.getHex(dragStartLocation).hideLayer(LMB);
        if (cursorLocation != null)
            boardInstance.getHex(cursorLocation).hideLayer(Hover);

        boardInstance.removeMarkers(dragStartLocation);
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}