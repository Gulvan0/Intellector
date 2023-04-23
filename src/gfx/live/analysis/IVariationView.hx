package gfx.live.analysis;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import gfx.utils.PlyScrollType;
import haxe.ui.core.Component;
import struct.Variant.VariantPath;

interface IVariantView
{
    public function init(eventHandler:PeripheralEvent->Void):Void;
    public function clear(?newStartingSituation:Situation):Void;
    public function addChildNode(parentPath:VariantPath, ply:RawPly, selectChild:Bool):Void;
    public function addChildToSelectedNode(ply:RawPly, selectChild:Bool):Void;
    public function getSelectedNode():VariantPath;
    public function removeNodeByPath(path:VariantPath):Void;
    public function handlePlyScrolling(type:PlyScrollType):Void;
}