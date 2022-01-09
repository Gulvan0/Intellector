package gameboard.states;

import openfl.geom.Point;
import struct.IntPoint;
import Networker.IncomingEvent;

class EnemyMoveDraggingState extends BaseDraggingState
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

    private override function getSelectedState(selectedHexLocation:IntPoint):BaseSelectedState
    {
        return new EnemyMoveSelectedState(boardInstance, selectedHexLocation, playerColor, premoves, cursorLocation);
    }

    public override function handleNetEvent(event:IncomingEvent)
    {
        //TODO: Fill
        //* For enemy move somthing like:
        //AssetManager.playPlySound(ply, shownSituation);
        //boardInstance.makeMove(ply);
        //state = ...
    }

    public function new(board:GameBoard, dragStartPosition:IntPoint, playerColor:PieceColor, premoves:Array<Ply> = [], ?cursorLocation:IntPoint)
    {
        super(board, dragStartPosition, cursorLocation);
        this.playerColor = playerColor;
        this.premoves = premoves;
    }
}