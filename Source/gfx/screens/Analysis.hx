package gfx.screens;

import haxe.Timer;
import gfx.components.Dialogs;
import struct.Variant;
import gameboard.states.NeutralState;
import gameboard.behaviors.AnalysisBehavior;
import js.Browser;
import dict.Dictionary;
import struct.PieceColor;
import gfx.analysis.RightPanel;
import gameboard.GameBoard;
import openfl.display.Sprite;

class Analysis extends Screen
{
    private var board:GameBoard;
    private var rightPanel:RightPanel;

    private var exploredStudyID:Int;

    public override function onEntered()
    {
        //* Do nothing
    }

    public override function onClosed()
    {
        //* Do nothing
    }

    public override function getURLPath():String
    {
        return "analysis";
    }

    //TODO: Connect observers with observed
    public function handleRightPanelEvent(event:RightPanelEvent)
    {
        switch event 
        {
            case AnalyzePressed(color):
                onAnalyzeRequested(color);
            case ExportSIPRequested:
                onExportSIPRequested();
            case ExportStudyRequested(variant):
                onExportStudyRequested(variant);
            case InitializationFinished:
                //TODO: Rewrite onReadyStudy & onReadyExplore and place it there
            default:
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
        super();
        //TODO: Fill (create components, dispose components, make links for UI and Network events)
    }
}