package gfx.game.analysis;

import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import net.shared.variation.ReadOnlyVariation;
import gfx.game.models.AnalysisBoardModel;
import haxe.ui.core.Component;
import gfx.game.events.VariationViewEvent;
import net.shared.variation.VariationPath;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import gfx.utils.PlyScrollType;

interface IVariationView
{
    public function init(model:IReadOnlyAnalysisBoardModel, eventHandler:VariationViewEvent->Void):Void;
    public function updateVariation(variation:ReadOnlyVariation, selectedNodePath:VariationPath, fullSelectedBranch:VariationPath):Void;
    public function updateSelectedNode(selectedNodePath:VariationPath, fullSelectedBranch:VariationPath):Void;
    public function asComponent():Component;
}