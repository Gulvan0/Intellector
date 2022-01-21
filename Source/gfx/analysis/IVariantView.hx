package gfx.analysis;

import gfx.analysis.RightPanel.RightPanelEvent;

interface IVariantView 
{
    public function selectBranch(branch:Array<Int>):Void;
    public function removeNode(path:Array<Int>, referenceVariant:Variant):Void;
    public function addChildNode(parentPath:Array<Int>, nodeText:String, selected:Bool, referenceVariant:Variant):Void;
    public function init(onBranchSelect:Array<Int>->Void, onBranchRemove:Array<Int>->Void):Void;    
}