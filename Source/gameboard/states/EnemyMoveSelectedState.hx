package gameboard.states;

import struct.IntPoint;
import Networker.IncomingEvent;

class EnemyMoveSelectedState extends BaseSelectedState
{
    private final playerColor:PieceColor;
    private var premoves:Array<Ply>;

    private override function getNeutralState():BaseNeutralState
    {
        return new EnemyMoveNeutralState(boardInstance, playerColor, premoves, cursorLocation);
    }

    private override function onMoveChosen(ply:Ply)
    {
        //TODO: Fill
    }

    private override function getDraggingState(dragDepartureLocation:IntPoint):BaseDraggingState
    {
        return new EnemyMoveDraggingState(boardInstance, dragDepartureLocation, playerColor, premoves, cursorLocation);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //TODO: Fill
        //* For enemy move somthing like:
        //AssetManager.playPlySound(ply, shownSituation);
        //boardInstance.makeMove(ply);
        //state = ...
    }

    public function new(board:GameBoard, selectedDepartureLocation:IntPoint, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, selectedDepartureLocation, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}