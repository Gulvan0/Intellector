package client.ui.common.board;

import intellectorboard.primitives.hex.HexCoords;

/** Per-hex fills overriding the base ones; only `HexTints` writes them, to respect tint priority **/
interface HexFillTarget
{
    public function setHexFill(coords:HexCoords, color:String):Void;

    /** Reverts `coords` to its base fill **/
    public function resetHexFill(coords:HexCoords):Void;
}
