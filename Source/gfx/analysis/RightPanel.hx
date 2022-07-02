package gfx.analysis;

import gfx.analysis.IVariantView.SelectedBranchInfo;
import gameboard.GameBoard.IGameBoardObserver;
import serialization.PlySerializer;
import gfx.screens.Analysis.NodeInfo;
import gameboard.GameBoard.GameBoardEvent;
import serialization.SituationSerializer;
import haxe.ui.core.Component;
import openfl.text.TextFormat;
import openfl.events.Event;
import haxe.ui.components.Image;
import struct.Ply;
import utils.AssetManager;
import gfx.common.MoveNavigator;
import js.Browser;
import dict.Phrase;
import haxe.Timer;
import struct.Situation;
import struct.Variant;
import haxe.ui.styles.Style;
import gfx.utils.PlyScrollType;
import struct.Variant;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Box;
import haxe.ui.components.OptionBox;
import struct.PieceColor;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import dict.Dictionary;
import haxe.ui.containers.Grid;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
import gfx.analysis.PosEditMode;
import haxe.ui.util.Variant as UIVariant;
using utils.CallbackTools;

enum RightPanelEvent
{
    BranchSelected(branch:Array<Ply>, startingSituation:Situation, pointer:Int);
    RevertNeeded(plyCnt:Int);
    ClearRequested;
    ResetRequested;
    ConstructSituationRequested(situation:Situation);
    TurnColorChanged(newTurnColor:PieceColor);
    ApplyChangesRequested;
    DiscardChangesRequested;
    EditModeChanged(newEditMode:PosEditMode);
    EditorEntered;
    ScrollBtnPressed(type:PlyScrollType);
    ExportSIPRequested;
    ExportStudyRequested(variantStr:String);
    InitializationFinished;
}

interface RightPanelObserver
{
    public function handleRightPanelEvent(event:RightPanelEvent):Void;    
}

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/right_panel.xml"))
class RightPanel extends HBox implements IGameBoardObserver
{
    public var observers(default, null):Array<RightPanelObserver> = [];

    private function emit(event:RightPanelEvent)
    {
        for (obs in observers)
            obs.handleRightPanelEvent(event);
    }

    /* Deprecated
    private function handleOverviewTabEvent(event:OverviewTabEvent)
    {
        switch event 
        {
            case ExportSIPRequested:
                emit(ExportSIPRequested);
            case ExportStudyRequested:
                emit(ExportStudyRequested(branchingTab.variantView.getSerializedVariant()));
            case ScrollBtnPressed(type):
                emit(ScrollBtnPressed(type));
            case SetPositionPressed:
                showPositionEditor();
                emit(EditorEntered);
        }
    }

    private function handlePositionEditorEvent(event:PositionEditorEvent)
    {
        switch event 
        {
            case ClearPressed:
                emit(ClearRequested);
            case ResetPressed:
                emit(ResetRequested);
            case ConstructFromSIPPressed(sip):
                var situation:Situation = SituationSerializer.deserialize(sip);
                positionEditor.changeColorOptions(situation.turnColor);
                emit(ConstructSituationRequested(situation));
            case TurnColorChanged(newTurnColor):
                emit(TurnColorChanged(newTurnColor));
            case ApplyChangesPressed:
                overviewTab.navigator.clear();
                showControlTabs();
                emit(ApplyChangesRequested);
            case DiscardChangesPressed:
                showControlTabs();
                emit(DiscardChangesRequested);
            case EditModeChanged(newEditMode):
                emit(EditModeChanged(newEditMode));
        }
    }

    private function onBranchSelected(branchInfo:SelectedBranchInfo)
    {
        overviewTab.navigator.rewrite(branchInfo.plyStrArray);
        emit(BranchSelected(branchInfo.plyArray, branchingTab.variantView.getStartingSituation(), branchInfo.selectedPlyNum));
    }

    private function onRevertRequestedByBranchingTab(plysToRevert:Int)
    {
        overviewTab.navigator.revertPlys(plysToRevert);
        emit(RevertNeeded(plysToRevert));
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case ContinuationMove(ply, plyStr, performedBy):
                branchingTab.variantView.addChildToSelectedNode(ply, true);
                overviewTab.navigator.writePlyStr(plyStr);
                positionEditor.changeColorOptions(opposite(performedBy));
            case SubsequentMove(plyStr, performedBy):
                positionEditor.changeColorOptions(opposite(performedBy));
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                var plysToRevertCnt = branchLength - plyPointer;
                branchingTab.variantView.addChildToSelectedNode(ply, true);
                overviewTab.navigator.revertPlys(plysToRevertCnt);
                overviewTab.navigator.writePlyStr(plyStr);
                positionEditor.changeColorOptions(opposite(performedBy));
            case SituationEdited(newSituation):
                branchingTab.variantView.clear(newSituation);
            default:
        }
    }

    public function showPositionEditor() 
    {
        positionEditor.returnToDefaultEditMode();
        controlTabs.visible = false;
        positionEditor.visible = true;
    }

    public function showControlTabs() 
    {
        positionEditor.visible = false;
        controlTabs.visible = true;
    }

    
    PositionEditor:

        public function returnToDefaultEditMode()
        {
            pressedEditModeBtn.selected = false;
            defaultEditModeBtn.selected = true;
            pressedEditModeBtn = defaultEditModeBtn;
        }

        public function changeColorOptions(selectedColor:PieceColor) 
        {
            turnColorSelectOptions[selectedColor].selected = true;
            turnColorSelectOptions[opposite(selectedColor)].selected = false;
        }

    BranchingTab:
        public function new(type:BranchingTabType, initialVariant:Variant, onBranchSelected:SelectedBranchInfo->Void, onRevertNeeded:(plysToRevert:Int)->Void)
        {
            super();

            switch type 
            {
                case Tree:
                    var variantTree = new VariantTree(initialVariant);
                    //addComponent(variantTree);
                    variantView = variantTree;
                case Outline:
                    //Fill
                case PlainText:
                    //Fill
            }

            variantView.init(onBranchSelected, onRevertNeeded); 
        }

    public function new(initialVariant:Variant) 
    {
        super();

        positionEditor = new PositionEditor();
        positionEditor.changeColorOptions(initialVariant.startingSituation.turnColor);
        controlTabs = createControlTabs(initialVariant);

        positionEditor.init(handlePositionEditorEvent);
        overviewTab.init(initialVariant.startingSituation.turnColor, handleOverviewTabEvent);
        
        var fullBox:HBox = new HBox();
        fullBox.addComponent(positionEditor);
        fullBox.addComponent(controlTabs);
        addChild(fullBox);
    }*/

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        
    }

    public function new()
    {
        super();
    }
}