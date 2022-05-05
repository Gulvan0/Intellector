package gfx.analysis;

import struct.Variant.VariantPath;
import struct.Situation;
import struct.Ply;

class SelectedBranchInfo
{
    public var selectedPlyNum:Int;
    public var plyArray:Array<Ply>;
    public var plyStrArray:Array<String>;

    public function new()
    {
        
    }
}

interface IVariantView
{
    public function init(onBranchSelect:SelectedBranchInfo->Void, onRevertNeeded:Int->Void):Void;
    public function clear(?newStartingSituation:Situation):Void;
    public function addChildNode(parentPath:VariantPath, ply:Ply, selectChild:Bool):Void;
    public function addChildToSelectedNode(ply:Ply, selectChild:Bool):Void;
    public function removeNode(path:VariantPath):Void;
    public function getSerializedVariant():String;
    public function getSelectedBranch():VariantPath;
    public function getStartingSituation():Situation;    
}