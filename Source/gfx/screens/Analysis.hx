package gfx.screens;

import js.Browser;
import dict.Dictionary;
import struct.PieceColor;
import gfx.analysis.RightPanel;
import gameboard.GameBoard;
import openfl.display.Sprite;

class Analysis extends Sprite
{
    private var board:GameBoard;
    private var rightPanel:RightPanel;

    private var exploredStudyID:Int;

    //TODO: Add the same handler to board
    //TODO: Connect observers with observed
    public function handleRightPanelEvent(event:RightPanelEvent)
    {
        switch event 
        {
            case ApplyChangesRequested:
                //TODO: Fill (Think!). Do not forget to reset the variant and the variantView (correctly update it somehow)
            case DiscardChangesRequested:
                //TODO: Fill (Think!). We need to preserve the former variant and just move pieces on the gameboard
            case AnalyzePressed(color):
                onAnalyzeRequested(color);
            case ExportSIPRequested:
                onExportSIPRequested();
            case ExportStudyRequested(variant):
                onExportStudyRequested(variant);
            case InitializationFinished:
                //TODO: Rewrite onReadyStudy & onReadyExplore and place it there
        }
    }

    private function onExportStudyRequested(variant:Variant)
    {
        if (exploredStudyID != null)
            Dialogs.confirm(Dictionary.getPhrase(STUDY_OVERWRITE_CONFIRMATION_MESSAGE), Dictionary.getPhrase(STUDY_OVERWRITE_CONFIRMATION_TITLE), () -> {
                Timer.delay(exportStudyAskName.bind(variant, exploredStudyID), 20);
            }, () -> {
                Timer.delay(exportStudyAskName.bind(variant, null), 20);
            });
        else
            exportStudyAskName(variant, null);
    }

    private function exportStudyAskName(variant:Variant, decidedOverwriteID:Null<Int>) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(STUDY_NAME_SELECTION_MESSAGE));
        if (response != null)
            Networker.emitEvent(SetStudy(response.substr(0, 40), variant.serialize(), decidedOverwriteID));
    }

    private function onExportSIPRequested() 
    {
        var sip:String = board.shownSituation.serialize();
        Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), sip);
    }

    private function onAnalyzeRequested(color:PieceColor)
    {
        //* Deprecated logic moved from another place
        /*var situation:Situation = field.shownSituation.copy();
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
        }, 20);*/
    }

    public function new()
    {

    }
}