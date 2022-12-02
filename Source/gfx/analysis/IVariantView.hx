package gfx.analysis;

import gfx.utils.PlyScrollType;
import haxe.ui.core.Component;
import struct.Variant.VariantPath;

interface IVariantView
{
    public function init(eventHandler:PeripheralEvent->Void):Void;
    public function clear(?newStartingSituation:Situation):Void;
    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool):Void;
    public function addChildToSelectedNode(ply:Ply, selectChild:Bool):Void;
    public function getSelectedNode():VariantPath;
    public function removeNodeByPath(path:VariantPath):Void;
    public function handlePlyScrolling(type:PlyScrollType):Void;
}