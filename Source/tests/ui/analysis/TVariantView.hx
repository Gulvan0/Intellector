package tests.ui.analysis;

import tests.ui.analysis.variantviews.AugmentedVariantTree;
import Preferences.BranchingTabType;
import tests.ui.TestedComponent;
import serialization.PlySerializer;
import struct.Ply;
import struct.Variant;
import struct.Situation;
import openfl.display.Sprite;
import gfx.analysis.IVariantView;

interface ITestedVariantView extends IVariantView
{
    public function getComponent():ComponentGraphics;
    public function _imitateEvent(encodedEvent:String):Void;
    public function getCurrentSituation():Situation;
}

enum StartingVariantType 
{
    Empty;
    StraightSequence;
    Branching;
}

class TVariantView extends TestedComponent
{
    private var variantView:ITestedVariantView;

    private var _initparam_type:BranchingTabType = Tree;

    private var _initparam_variant:StartingVariantType = Empty;

    public override function _provide_situation():Situation 
    {
        return variantView.getCurrentSituation();
    }

    private function _act_addOneRandomToSelected() 
    {
        variantView.addChildToSelectedNode(variantView.getCurrentSituation().randomContinuation(1)[0].ply, false);
    }

    private function _act_clear() 
    {
        variantView.clear();
    }

    private override function getComponent():ComponentGraphics
    {
		return variantView.getComponent();
    }

    private override function rebuildComponent()
    {
        var startingVariant:Variant = new Variant(Situation.starting());
        var selectedPath:VariantPath = [];
        switch _initparam_variant 
        {
            case StraightSequence:
                var parentPath:Array<Int> = [];
                for (plyInfo in Situation.starting().randomContinuation(12))
                {
                    startingVariant.addChildToNode(plyInfo.ply, parentPath);
                    parentPath.push(0);
                }
                selectedPath = [0,0,0,0,0,0];
            case Branching:
                startingVariant.addChildToNode(PlySerializer.deserialize("7573"), []);
                startingVariant.addChildToNode(PlySerializer.deserialize("8182"), [0]);
                startingVariant.addChildToNode(PlySerializer.deserialize("6564"), [0, 0]);
                startingVariant.addChildToNode(PlySerializer.deserialize("1513"), [0, 0]);
                startingVariant.addChildToNode(PlySerializer.deserialize("6654"), []);
                selectedPath = [0];
            case Empty:
                //* Leave it as it is
        }

        variantView = switch _initparam_type 
        {
            case Tree:
                new AugmentedVariantTree(startingVariant, selectedPath);
            case Outline:
                new AugmentedVariantTree(startingVariant, selectedPath); //TODO: Replace with AugmentedOutline
            case PlainText:
                new AugmentedVariantTree(startingVariant, selectedPath); //TODO: Replace with AugmentedPlainText
        }

        variantView.init(p->{trace(p.plyStrArray.join(' -> '));}, p->{trace(p);});
    }

    public override function imitateEvent(encodedEvent:String)
    {
        variantView._imitateEvent(encodedEvent);
    }
}