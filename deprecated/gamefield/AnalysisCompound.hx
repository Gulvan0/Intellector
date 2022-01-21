package gfx.components.gamefield;

class AnalysisCompound extends GameCompound 
{
    private var panel:RightPanel;
    private var variant:Variant;
    private var overwriteID:Null<Int> = null;

    private function onMoveMade(ply:Ply)
    {
        if (field.plyPointer == field.plyHistory.length)
            onContinuationMove(ply);
        else if (field.plyHistory[field.plyPointer].equals(ply.toReversible(field.shownSituation)))
            onSubsequentMove(ply);
        else
            onBranchingMove(ply);
        panel.updateBranchingTabContentSize();
        panel.changeEditorColorOptions(field.shownSituation.turnColor);
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
        var extendedPath:Array<Int> = variant.extendPathLeftmost(path);
        panel.variantTree.selectBranch(extendedPath);
        panel.deprecateScore();
        panel.navigator.clear();
        cast(field, AnalysisField).reset();
        var plys:Array<Ply> = variant.getBranchByPath(extendedPath);
        var situation = field.currentSituation.copy();
        for (i in 0...plys.length)
        {
            var ply:Ply = plys[i];
            if (i < path.length)
            {
                field.move(ply, Actualization);
                field.appendToHistory(ply);
            }
            else
                field.appendToHistory(ply, false);
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

    private function onConstructFromSIPPressed(sip:String)
    {
        constructFromSIP(sip, false);
    }

    private function constructFromSIP(sip:String, overrideLastApprovedSIP:Bool) 
    {
        cast(field, AnalysisField).constructFromSIP(sip, overrideLastApprovedSIP);
        panel.changeEditorColorOptions(field.currentSituation.turnColor);
        variant = new Variant();
        panel.variantTree.init(variant, []);
    }

    private function onApplyChangesPressed()
    {
        panel.navigator.clear();
        panel.deprecateScore();
        panel.showControlTabs();
        cast(field, AnalysisField).applyChanges();
    }

    private function onDiscardChangesPressed()
    {
        panel.navigator.clear();
        panel.showControlTabs();
        cast(field, AnalysisField).discardChanges();
    }

    private function onTurnColorChanged(color:PieceColor)
    {
        field.currentSituation.setTurnWithZobris(color);
    }

    private function onExportStudyRequested()
    {
        if (overwriteID != null)
            Dialogs.confirm(Dictionary.getPhrase(STUDY_OVERWRITE_CONFIRMATION_MESSAGE), Dictionary.getPhrase(STUDY_OVERWRITE_CONFIRMATION_TITLE), () -> {
                Timer.delay(exportStudyAskName.bind(overwriteID), 20);
            }, () -> {
                Timer.delay(exportStudyAskName.bind(null), 20);
            });
        else
            exportStudyAskName(null);
    }

    private function exportStudyAskName(decidedOverwriteID:Null<Int>) 
    {
        var response = Browser.window.prompt(Dictionary.getPhrase(STUDY_NAME_SELECTION_MESSAGE));
        if (response != null)
        {
            Networker.emitEvent(SetStudy(response.substr(0, 40), variant.serialize(), decidedOverwriteID));
        }
    }

    private function onEditModeChanged(mode:Null<PosEditMode>)
    {
        if (cast(field, AnalysisField).editMode == null)
        {
            field.highlightMove([]);
            variant = new Variant();
            panel.variantTree.init(variant, []);
        }
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

    private function onReadyStudy(studyOverview:StudyOverview)
    {
        if (studyOverview.data.author.toLowerCase() == Networker.login.toLowerCase())
            overwriteID = studyOverview.id;

        var variantStrParts:Array<String> = studyOverview.data.variantStr.split(";");
        var startingSIP = variantStrParts.pop();

        constructFromSIP(startingSIP, true);

        if (Lambda.empty(variantStrParts))
            return;

        var nodesByPathLength:Map<Int, Array<{path:Array<Int>, plyStr:String}>> = [];
        var maxPathLength:Int = 0;
        for (line in variantStrParts)
        {
            var lineParts = line.split("/");
            var code = lineParts[0];
            var path = code.split(":").map(Std.parseInt);
            var plyStr = lineParts[1];
            if (path.length > maxPathLength)
                maxPathLength = path.length;

            var nodes = nodesByPathLength.get(path.length);
            if (nodes == null)
                nodesByPathLength.set(path.length, [{path: path, plyStr: plyStr}]);
            else
                nodes.push({path: path, plyStr: plyStr});
        }
        for (i in 1...(maxPathLength+1))
            for (node in nodesByPathLength.get(i))
            {
                onBranchClick(Variant.parentPath(node.path));
                onBranchingMove(PlyDeserializer.deserialize(node.plyStr));
            }
        onBranchClick([]);
    }

    private function onReadyExplore(situationSIP:String)
    {
        constructFromSIP(situationSIP, true);
    }

    public function new(onReturn:Void->Void, ?studyOverview:StudyOverview, ?situationSIP:String)
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
        panel.onExportSIPRequested = onExportSIPRequested;
        panel.onExportStudyRequested = onExportStudyRequested;
        panel.onBranchClick = onBranchClick;
        panel.onBranchCtrlClick = onBranchCtrlClick;
        panel.onTurnColorChanged = onTurnColorChanged;
        panel.onApplyChangesPressed = onApplyChangesPressed;
        panel.onDiscardChangesPressed = onDiscardChangesPressed;
        panel.onEditModeChanged = onEditModeChanged;
        panel.scrollingCallback = field.applyScrolling;
        
        if (studyOverview != null)
        {
            if (situationSIP != null)
                throw "AnalysisCompound.new(): Either studyOverview or situationSIP should be omitted";
            panel.readyCallback = onReadyStudy.bind(studyOverview);
        }
        else if (situationSIP != null)
            panel.readyCallback = onReadyExplore.bind(situationSIP);
        else
            panel.readyCallback = () -> {};

        addChild(panel);

        variant = new Variant();
        panel.variantTree.init(variant, []);
    }
}