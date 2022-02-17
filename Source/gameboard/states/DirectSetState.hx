package gameboard.states;

import struct.Hex;

class DirectSetState extends BaseState
{
    private var prototypeHex:Hex;

    private override function abortMove()
    {
        //* Do nothing
    }

    public override function onLMBPressed(location:Null<IntPoint>)
    {
        if (location != null)
            boardInstance.setHexDirectly(location, prototypeHex);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public override function onLMBReleased(location:Null<IntPoint>)
    {
        //* Do nothing
    }

    public function new(board:GameBoard, prototypeHex:Hex, ?cursorLocation:IntPoint)
    {
        super(board, cursorLocation);
        this.prototypeHex = prototypeHex;
    }
}