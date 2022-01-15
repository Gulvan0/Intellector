package gameboard.states;

import struct.IntPoint;
import struct.Hex;
import net.ServerEvent;

class EnemyMoveSelectedState extends BaseSelectedState
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

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new EnemyMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, premoves, cursorLocation);
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
        removeMarkers(selectedDepartureLocation);
        boardInstance.getHex(selectedDepartureLocation).hideLayer(LMB);
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}