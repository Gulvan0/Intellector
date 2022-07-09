package gfx.analysis;

import haxe.ui.core.Component;
import struct.Variant.VariantPath;
import struct.Situation;
import struct.Ply;

interface IVariantView
{
    public function init(eventHandler:PeripheralEvent->Void):Void;
    public function clear(?newStartingSituation:Situation):Void;
    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool):Void;
    public function addChildToSelectedNode(ply:Ply, selectChild:Bool):Void;
    public function removeNode(path:VariantPath):Void;
}