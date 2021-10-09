package gfx.components.gamefield;

import gfx.components.gamefield.analysis.PosEditMode;
import struct.Situation;
import haxe.Timer;
import struct.PieceColor;
import analysis.AlphaBeta;
import dict.Dictionary;
import js.Browser;
import struct.Variant;
import struct.Ply;
import gfx.components.gamefield.modules.Field;
import gfx.components.gamefield.analysis.RightPanel;
import gfx.components.gamefield.modules.gameboards.AnalysisField;

class AnalysisCompound extends GameCompound 
{
    private var panel:RightPanel;
    private var variant:Variant;

    private function onMoveMade(ply:Ply)
    {
        if (field.plyPointer == field.plyHistory.length)
            onContinuationMove(ply);
        else if (field.plyHistory[field.plyPointer].equals(ply.toReversible(field.shownSituation)))
            onSubsequentMove(ply);
        else
            onBranchingMove(ply);
        panel.updateBranchingTabContentSize();
    }

    private function onContinuationMove(ply:Ply)
    {
        var parentPath = panel.variantTree.selectedBranch.copy();
        panel.variantTree.addChildNode(parentPath, ply.toNotation(field.shownSituation), true, variant);
        panel.navigator.writePly(ply, field.shownSituation);
        field.appendToHistory(ply);
        variant.addChildToNode(ply, parentPath);
    }

    private function onSubsequentMove(ply:Ply) 
    {
        panel.deprecateScore();
        field.plyPointer++;
        field.shownSituation = field.shownSituation.makeMove(ply);
    }

    private function onBranchingMove(ply:Ply) 
    {
        panel.deprecateScore();
        var plyNum = field.plyPointer;
        var plysToRevertCnt = field.plyHistory.length - plyNum;
        var parentPath = panel.variantTree.selectedBranch.slice(0, plyNum);
        panel.variantTree.addChildNode(parentPath, ply.toNotation(field.shownSituation), true, variant);
        field.revertToShown();
        panel.navigator.revertPlys(plysToRevertCnt);
        panel.navigator.writePly(ply, field.shownSituation);
        field.appendToHistory(ply);
        variant.addChildToNode(ply, parentPath);
    }

    private function onBranchClick(path:Array<Int>) 
    {
        panel.variantTree.selectBranch(path);
        panel.deprecateScore();
        panel.navigator.clear();
        cast(field, AnalysisField).reset();
        var plys:Array<Ply> = variant.getBranchByPath(variant.extendPathLeftmost(path));
        var situation = field.currentSituation.copy();
        for (i in 0...plys.length)
        {
            var ply:Ply = plys[i];
            if (i < path.length)
            {
                field.move(ply, Actualization);
                field.appendToHistory(ply);
            }
            panel.navigator.writePly(ply, situation);
            situation = situation.makeMove(ply);
        }
    }

    private function onBranchCtrlClick(path:Array<Int>)
    {
        if (Variant.belongs(path, panel.variantTree.selectedBranch))
        {
            var plysToRevertCnt:Int = panel.variantTree.selectedBranch.length - path.length + 1;
            panel.variantTree.selectBranch(Variant.parentPath(path));
            field.revertPlys(plysToRevertCnt);
            panel.navigator.revertPlys(plysToRevertCnt);
        }
        panel.variantTree.removeNode(path, variant);
        variant.removeNode(path);
        panel.updateBranchingTabContentSize();
    }

    private function onClearPressed() 
    {
        panel.clearAnalysisScore();
        cast(field, AnalysisField).clearBoard();
    }

    private function onResetPressed() 
    {
        panel.clearAnalysisScore();
        cast(field, AnalysisField).reset();
    }

    private function onExportSIPRequest() 
    {
        var sip:String = field.shownSituation.serialize();
        Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
    }

    private function onConstructFromSIPPressed(sip:String)
    {
        cast(field, AnalysisField).constructFromSIP(sip);
        panel.changeEditorColorOptions(field.currentSituation.turnColor);
        variant = new Variant();
        panel.variantTree.init(variant, []);
    }

    private function onApplyChangesPressed()
    {
        panel.navigator.clear();
        panel.variantTree.init(variant, []);
        panel.deprecateScore();
        panel.showControlTabs();
        cast(field, AnalysisField).applyChanges();
    }

    private function onDiscardChangesPressed()
    {
        panel.navigator.clear();
        panel.variantTree.init(variant, []);
        panel.showControlTabs();
        cast(field, AnalysisField).discardChanges();
    }

    private function onTurnColorChanged(color:PieceColor)
    {
        field.currentSituation.setTurnWithZobris(color);
    }

    private function onEditModeChanged(mode:Null<PosEditMode>)
    {
        if (cast(field, AnalysisField).editMode == null)
            field.highlightMove([]);
        cast(field, AnalysisField).changeEditMode(mode);
    }

    private function onAnalyzePressed(color:PieceColor) 
    {
        panel.displayLoadingOnScoreLabel();

        var situation:Situation = field.shownSituation.copy();
        situation.setTurnWithZobris(color);
        AlphaBeta.initMeasuredIndicators();

        Timer.delay(() -> {
            var result = AlphaBeta.findMate(situation, 10, situation.turnColor == White);//AlphaBeta.evaluate(situation, 6);
            #if measure_time
            trace("Prune count: " + AlphaBeta.prunedCount + "; Prune ratio: " + AlphaBeta.prunedCount / (AlphaBeta.prunedCount + AlphaBeta.evaluatedCount));
            for (act in MeasuredProcess.createAll())
            {
                trace(act.getName());
                trace("Calls: " + AlphaBeta.calls[act] + "; Avg: " + (AlphaBeta.totalTime[act] / AlphaBeta.calls[act]) + "; Total: " + AlphaBeta.totalTime[act]);
            }
            #end
            var recommendedMove = result.optimalPly;
                
            panel.displayAnalysisResults(result);
            field.rmbSelectionBackToNormal();
            field.drawArrow(recommendedMove.from, recommendedMove.to);
        }, 20);
    }

    public function new(onReturn:Void->Void)
    {
        var field = new AnalysisField();
        field.onOwnMoveMade = onMoveMade;

        super(Analysis, field, null, null, null, onReturn);

        panel = new RightPanel();
        panel.x = field.right + 10;
        panel.y = field.top;
        panel.onClearPressed = onClearPressed;
        panel.onResetPressed = onResetPressed;
        panel.onAnalyzePressed = onAnalyzePressed;
        panel.onConstructFromSIPPressed = onConstructFromSIPPressed;
        panel.onExportSIPRequested = onExportSIPRequest;
        panel.onBranchClick = onBranchClick;
        panel.onBranchCtrlClick = onBranchCtrlClick;
        panel.onTurnColorChanged = onTurnColorChanged;
        panel.onApplyChangesPressed = onApplyChangesPressed;
        panel.onDiscardChangesPressed = onDiscardChangesPressed;
        panel.onEditModeChanged = onEditModeChanged;
        panel.scrollingCallback = field.applyScrolling;
        addChild(panel);

        variant = new Variant();
        panel.variantTree.init(variant, []);
    }
}