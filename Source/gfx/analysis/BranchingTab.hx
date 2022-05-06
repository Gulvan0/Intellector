package gfx.analysis;

import gfx.analysis.IVariantView;
import struct.Variant;
import haxe.ui.containers.ScrollView;
import Preferences.BranchingTabType;

class BranchingTab extends ScrollView //TODO: Extend VBox, ...
{
    public var variantView:IVariantView; //TODO: Ensure all methods perform shallow argument copying

    public function new(type:BranchingTabType, initialVariant:Variant, onBranchSelected:SelectedBranchInfo->Void, onRevertNeeded:(plysToRevert:Int)->Void)
    {
        super();

        switch type 
        {
            case Tree:
                var variantTree = new VariantTree(initialVariant);
                //addComponent(variantTree);
                variantView = variantTree;
            case Outline:
                //TODO: Fill
            case PlainText:
                //TODO: Fill
        }

        variantView.init(onBranchSelected, onRevertNeeded); 
    }
}