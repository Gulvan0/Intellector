package gfx.live.analysis;

import gfx.live.interfaces.ReadOnlyVariation;
import gfx.live.models.AnalysisBoardModel;
import haxe.ui.core.Component;
import gfx.live.events.VariationViewEvent;
import net.shared.variation.VariationPath;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import gfx.utils.PlyScrollType;

interface IVariationView
{
    public function init(model:AnalysisBoardModel, eventHandler:VariationViewEvent->Void):Void;
    public function updateVariation(variation:ReadOnlyVariation, selectedNodePath:VariationPath, fullSelectedBranch:VariationPath):Void;
    public function updateSelectedNode(selectedNodePath:VariationPath, fullSelectedBranch:VariationPath):Void;
    public function asComponent():Component;
}