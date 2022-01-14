package gameboard.states;

import struct.Ply;
import Networker.ServerEvent;

class EnemyMoveNonPremovableState extends BaseState
{
    private final playerColor:PieceColor;

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public override function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
        //* For enemy move somthing like:
        //AssetManager.playPlySound(ply, shownSituation);
        //boardInstance.makeMove(ply);
        //state = ...
    }

    public function new(board:GameBoard, playerColor:PieceColor, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.playerColor = playerColor;
    }
}