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
        //TODO: Rewrite (both for branching and for continuation cases; check equality if possible branching)
        //panel.makeMove(ply);
    }

    private function onBranchClick(path:Array<Int>) 
    {
        //TODO: Deselect former selected, store selected, highlight arrows, redraw field's figures, reinit navigator
    }

    private function onBranchCtrlClick(path:Array<Int>)
    {
        //TODO: If belongs to a selected branch, select a new branch and redraw figures on a field, reinit navigator
        //variant.removeByCode(code);
        //variantTree.init(variant); //TODO: Remove and then add again TreeWrapper on TreeContainer. These components need to be stored in the properties
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
        var sip:String = field.currentSituation.serialize();
        Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
    }

    private function onConstructFromSIPPressed(sip:String)
    {
        cast(field, AnalysisField).constructFromSIP(sip);
    }

    private function onApplyChangesPressed()
    {
        panel.deprecateScore();
        panel.showControlTabs();
        cast(field, AnalysisField).applyChanges();
    }

    private function onDiscardChangesPressed()
    {
        panel.showControlTabs();
        cast(field, AnalysisField).discardChanges();
    }

    private function onTurnColorChanged(color:PieceColor)
    {
        field.currentSituation.setTurnWithZobris(color);
    }

    private function onEditModeChanged(mode:PosEditMode)
    {
        cast(field, AnalysisField).changeEditMode(mode);
    }

    private function onAnalyzePressed(color:PieceColor) 
    {
        panel.displayLoadingOnScoreLabel();

        var situation:Situation = field.currentSituation.copy();
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
        panel.x = field.x + field.width + 10;
        panel.y = field.y + (field.getHeight() - 40 - Math.sqrt(3) * Field.a) / 2;
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
    }
}