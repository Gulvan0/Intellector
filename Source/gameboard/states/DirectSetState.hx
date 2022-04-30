package gameboard.states;

import struct.IntPoint;
import struct.Hex;

class DirectSetState extends BaseState
{
    private var prototypeHex:Hex;

    public override function abortMove()
    {
        //* Do nothing
    }

    public override function onLMBPressed(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        if (location != null)
            boardInstance.setHexDirectly(location, prototypeHex);
    }

    public override function reactsToHover(location:IntPoint):Bool
    {
        return false;
    }

    public override function onLMBReleased(location:Null<IntPoint>, shiftPressed:Bool, ctrlPressed:Bool)
    {
        //* Do nothing
    }

    public function new(prototypeHex:Hex)
    {
        super();
        this.prototypeHex = prototypeHex;
    }
}