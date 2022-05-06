package tests.ui.analysis;

import struct.Variant;
import struct.Situation;
import openfl.display.Sprite;
import gfx.analysis.IVariantView;

class TVariantView extends Sprite
{
    private var variantView:IVariantView;

    private function _act_straightSequence()
    {
        var refVar:Variant = new Variant(Situation.starting());
        var parentPath:Array<Int> = [];
        for (plyInfo in Situation.starting().randomContinuation(12))
        {
            variantView.addChildNode(parentPath, plyInfo.ply, true);
            refVar.addChildToNode(plyInfo.ply, parentPath);
            parentPath.push(0);
        }
    }

    public function new(variantView:IVariantView) 
    {
        super();
        this.variantView = variantView;
        variantView.init(p->{trace(p);}, p->{trace(p);});
        if (Std.isOfType(variantView, Sprite))
            addChild(cast(variantView, Sprite));
        else
            throw "variantView should be Sprite";
    }
}