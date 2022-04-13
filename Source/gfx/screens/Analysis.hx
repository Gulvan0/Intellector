package gfx.screens;

import haxe.ui.containers.HBox;
import gfx.components.SpriteWrapper;
import serialization.SituationDeserializer;
import struct.Situation;
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

typedef NodeInfo = {path:Array<Int>, plyStr:String};

class Analysis extends Screen implements RightPanelObserver
{
    private var board:GameBoard;
    private var rightPanel:RightPanel;

    private var exploredStudyID:Int;

    private var nodesByPathLength:Map<Int, Array<NodeInfo>> = [];

    public override function onEntered()
    {
        //* Do nothing
    }

    public override function onClosed()
    {
        //* Do nothing
    }

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
                rightPanel.drawVariant(nodesByPathLength);
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
            //TODO: Update url and title (ID should be returned from server)
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

    public function new(?initialVariantStr:String, ?exploredStudyID:Int)
    {
        super();
        this.exploredStudyID = exploredStudyID;

        var variantStrParts:Array<String> = [];
        var startingSituation:Situation;
        var variantHasNodes:Bool;

        //TODO: Request study info from server if exploredStudyID != null && initialVariantStr == null

        if (initialVariantStr != null)
        {
            variantStrParts = initialVariantStr.split(";");
            var startingSituationSIP:String = variantStrParts.pop();
            startingSituation = SituationDeserializer.deserialize(startingSituationSIP);
            variantHasNodes = !Lambda.empty(variantStrParts);
        }
        else
        {
            startingSituation = Situation.starting();
            variantHasNodes = false;
        }

        if (variantHasNodes)
        {
            for (nodeStr in variantStrParts)
            {
                var nodeStrParts = nodeStr.split("/");
                var code = nodeStrParts[0];
                var path = code.split(":").map(Std.parseInt);
                var plyStr = nodeStrParts[1];
                var nodeInfo = {path: path, plyStr: plyStr};
    
                if (nodesByPathLength.exists(path.length))
                    nodesByPathLength[path.length].push(nodeInfo);
                else
                    nodesByPathLength.set(path.length, [nodeInfo]);
            }

            //For each level sort the corresponding nodes by their numbers (last elements of their paths)
            for (nodesOnSameLevelArray in nodesByPathLength)
                nodesOnSameLevelArray.sort((ni1, ni2) -> ni1.path[ni1.path.length - 1] - ni2.path[ni2.path.length - 1]);
        }

        board = new GameBoard(startingSituation, startingSituation.turnColor);
        board.init(new NeutralState(board), new AnalysisBehavior(board, startingSituation.turnColor));

        rightPanel = new RightPanel(startingSituation);

        var boardComponent = new SpriteWrapper();
        boardComponent.sprite = board;

        var rightPanelComponent = new SpriteWrapper();
        rightPanelComponent.sprite = rightPanel;

        var hbox = new HBox();
        hbox.addComponent(boardComponent);
        hbox.addComponent(rightPanelComponent);

        content.addComponent(hbox);
        
        board.addObserver(rightPanel);
        rightPanel.addObserver(board);
        rightPanel.addObserver(this);
    }
}