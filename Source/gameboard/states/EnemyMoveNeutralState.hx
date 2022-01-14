package gameboard.states;

import struct.Ply;
import Networker.ServerEvent;

class EnemyMoveNeutralState extends BaseNeutralState
{
    private final playerColor:PieceColor;
    private var premoves:Array<Ply>;

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new EnemyMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, premoves, cursorLocation);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return boardInstance.shownSituation.get(location).color == playerColor;
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        
        //* For enemy move somthing like:
        //AssetManager.playPlySound(ply, shownSituation);
        //boardInstance.makeMove(ply);
        //state = ...
    }

    public function new(board:GameBoard, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}