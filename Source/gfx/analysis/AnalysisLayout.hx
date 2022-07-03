package gfx.analysis;

import gameboard.behaviors.AnalysisBehavior;
import struct.Situation;
import struct.Variant;
import gfx.components.BoardWrapper;
import gfx.common.ShareDialog;
import gameboard.GameBoard;
import haxe.ui.containers.VBox;
import js.Browser;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/analysis/analysis_layout.xml'))
class AnalysisLayout extends VBox
{
    private var board:GameBoard;
    private var rightPanel:RightPanel;

    private override function validateComponentLayout():Bool 
    {
        if (Browser.window.innerWidth / Browser.window.innerHeight > 1.2) //Large mode
        {
            cCreepingLine.hidden = true;
            cActionBar.hidden = true;
            lRightBox.hidden = false;
        }
        else //Compact mode
        {
            cCreepingLine.hidden = false;
            cActionBar.hidden = false;
            lRightBox.hidden = true;
        }
        return super.validateComponentLayout();
    }

    public function onShareRequested(serializedVariant:String)
    {
        var exportNewCallback:String->Void = name -> {
            Networker.emitEvent(SetStudy(name, serializedVariant, null));
        };

        var overwriteCallback:Int->String->Void = (id:Int, name:String) -> {
            Networker.emitEvent(SetStudy(name, serializedVariant, id));
        };

        var shareDialog:ShareDialog = new ShareDialog();
        switch ScreenManager.currentScreenType 
        {
            case Analysis(initialVariantStr, exploredStudyID, exploredStudyName):
                if (exploredStudyID != null)
                    shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, exportNewCallback, overwriteCallback.bind(exploredStudyID), exploredStudyName);
                else
                    shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, exportNewCallback);
            default:
                throw "ShareRequested happened outside of Analysis screen!";
        }
        
        shareDialog.showShareDialog(board);
    }

    /*private function onActionBarButtonPressed(btnEvent:BtnPressEvent)
    {
        switch btnEvent 
        {
            case ChangeOrientation: 
                board.revertOrientation();
            case EditPosition:
                moveModeBtn.selected = true;
                controlTabs.hidden = true;
                positionEditor.hidden = false;
                eventHandler(EditorEntered);
            case Share: 
                onShareRequested(variantView.getSerializedVariant());
        }
    }*/

    public function new(?initialVariantStr:String)
    {
        super();

        var initialVariant:Variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.starting());
        var startingSituation:Situation = initialVariant.startingSituation;

        board = new GameBoard(startingSituation, startingSituation.turnColor, new AnalysisBehavior(startingSituation.turnColor), false);
        rightPanel = new RightPanel(initialVariant, onShareRequested, board.handleRightPanelEvent);
        
        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';

        boardContainer.addComponent(boardWrapper);
        lRightBox.addComponent(rightPanel);

        //TODO: cActionBar
        //TODO: cPositionEditor
        //TODO: cCreepingLine
        
        board.addObserver(rightPanel);
    }
}