package tests.ui.analysis;

import serialization.PlyDeserializer;
import struct.Ply;
import struct.Variant;
import struct.Situation;
import openfl.display.Sprite;
import gfx.analysis.IVariantView;

class TVariantView extends Sprite
{
    private var variantView:IVariantView;

    private function _act_initStraightSequence()
    {
        var parentPath:Array<Int> = [];
        for (plyInfo in Situation.starting().randomContinuation(12))
        {
            variantView.addChildNode(parentPath, plyInfo.ply, true);
            parentPath.push(0);
        }
    }

    private function _act_initSimpleBranching()
    {
        variantView.addChildNode([], PlyDeserializer.deserialize("7573"), true);
        variantView.addChildNode([0], PlyDeserializer.deserialize("8182"), true);
        variantView.addChildNode([0, 0], PlyDeserializer.deserialize("6564"), false);
        variantView.addChildNode([0, 0], PlyDeserializer.deserialize("1513"), false);
        variantView.addChildNode([], PlyDeserializer.deserialize("6654"), false);
    }

    #if debug
    private function _act_addOneRandomToSelected() 
    {
        variantView.addChildToSelectedNode(variantView.getCurrentSituation().randomContinuation(1)[0].ply, false);
    }
    #end

    private function _act_clear() 
    {
        variantView.clear();
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