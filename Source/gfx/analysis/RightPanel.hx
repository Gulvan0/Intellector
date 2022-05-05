package gfx.analysis;

import gameboard.GameBoard.IGameBoardObserver;
import serialization.PlyDeserializer;
import gfx.screens.Analysis.NodeInfo;
import gameboard.GameBoard.GameBoardEvent;
import serialization.SituationDeserializer;
import haxe.ui.core.Component;
import gfx.analysis.BranchingTab.BranchingTabEvent;
import gfx.analysis.PositionEditor.PositionEditorEvent;
import gfx.analysis.OverviewTab.OverviewTabEvent;
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

class RightPanel extends Sprite implements IGameBoardObserver
{
    public static var PANEL_WIDTH = 400;
    public static var PANEL_HEIGHT = 500;

    private var positionEditor:PositionEditor;
    private var controlTabs:TabView;

    private var overviewTab:OverviewTab;
    private var branchingTab:BranchingTab;

    private var observers:Array<RightPanelObserver> = [];
    
    public function addObserver(obs:RightPanelObserver)
    {
        observers.push(obs);
    }
    
    public function removeObserver(obs:RightPanelObserver)
    {
        observers.remove(obs);
    }

    private function emit(event:RightPanelEvent)
    {
        for (obs in observers)
            obs.handleRightPanelEvent(event);
    }

    private function handleOverviewTabEvent(event:OverviewTabEvent)
    {
        switch event 
        {
            case ExportSIPRequested:
                emit(ExportSIPRequested);
            case ExportStudyRequested:
                emit(ExportStudyRequested(branchingTab.variant.serialize()));
            case ScrollBtnPressed(type):
                emit(ScrollBtnPressed(type));
            case SetPositionPressed:
                showPositionEditor();
                emit(EditorEntered);
        }
    }

    private function handleBranchingTabEvent(event:BranchingTabEvent)
    {
        switch event 
        {
            case BranchSelected(branch, plyStrArray, startingSituation, pointer):
                overviewTab.navigator.clear();
                var color:PieceColor = startingSituation.turnColor;
                for (plyStr in plyStrArray)
                {
                    overviewTab.navigator.writePlyStr(plyStr, color);
                    color = opposite(color);
                }
                emit(BranchSelected(branch, startingSituation, pointer));
            case RevertNeeded(plyCnt):
                overviewTab.navigator.revertPlys(plyCnt);
                emit(RevertNeeded(plyCnt));
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
                var situation:Situation = SituationDeserializer.deserialize(sip);
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

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case ContinuationMove(ply, plyStr, performedBy):
                var parentPath = branchingTab.selectedBranch.copy();
                branchingTab.variantView.addChildNode(parentPath, plyStr, true, branchingTab.variant);
                overviewTab.navigator.writePlyStr(plyStr, performedBy);
                branchingTab.variant.addChildToNode(ply, parentPath);
                branchingTab.updateContentSize();
                positionEditor.changeColorOptions(opposite(performedBy));
            case SubsequentMove(plyStr, performedBy):
                branchingTab.updateContentSize();
                positionEditor.changeColorOptions(opposite(performedBy));
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                var plysToRevertCnt = branchLength - plyPointer;
                var parentPath = branchingTab.selectedBranch.slice(0, plyPointer);
                branchingTab.variantView.addChildNode(parentPath, plyStr, true, branchingTab.variant);
                overviewTab.navigator.revertPlys(plysToRevertCnt);
                overviewTab.navigator.writePlyStr(plyStr, performedBy);
                branchingTab.variant.addChildToNode(ply, parentPath);
                branchingTab.updateContentSize();
                positionEditor.changeColorOptions(opposite(performedBy));
            case SituationEdited(newSituation):
                branchingTab.clearVariant(newSituation);
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

    public function drawVariant(nodesByPathLength:Map<Int, Array<NodeInfo>>)
    {
        var maxPathLength:Int = 0;
        for (k in nodesByPathLength.keys())
            if (k > maxPathLength)
                maxPathLength = k;

        for (len in 1...maxPathLength)
            for (node in nodesByPathLength.get(len))
            {
                var parentPath = Variant.parentPath(node.path);
                branchingTab.variantView.addChildNode(parentPath, node.plyStr, false, branchingTab.variant);
                branchingTab.variant.addChildToNode(PlyDeserializer.deserialize(node.plyStr), parentPath);
            }
    }

    public function new(startingSituation:Situation) 
    {
        super();

        positionEditor = new PositionEditor();
        positionEditor.changeColorOptions(startingSituation.turnColor);
        controlTabs = createControlTabs(startingSituation);

        positionEditor.init(handlePositionEditorEvent);
        overviewTab.init(handleOverviewTabEvent);
        branchingTab.init(handleBranchingTabEvent);
        
        var fullBox:HBox = new HBox();
        fullBox.addComponent(positionEditor);
        fullBox.addComponent(controlTabs);
        addChild(fullBox);
    }

    private function onControlTabsAdded(e) 
    {
        controlTabs.removeEventListener(Event.ADDED_TO_STAGE, onControlTabsAdded);
        controlTabs.pageIndex = 1;

        Timer.delay(() -> {
            overviewTab.init(handleOverviewTabEvent);
            branchingTab.init(handleBranchingTabEvent);
            positionEditor.init(handlePositionEditorEvent);
            controlTabs.pageIndex = 0;
            emit(InitializationFinished);
        }, 20);
    }

    private function createControlTabs(startingSituation:Situation):TabView
    {
        overviewTab = new OverviewTab();
        branchingTab = new BranchingTab(Preferences.branchingTabType.get(), startingSituation, 390, 360);

        var openingTeaserLabel:Label = new Label();
        openingTeaserLabel.customStyle = {fontSize: 20};
        openingTeaserLabel.horizontalAlign = 'center';
        openingTeaserLabel.verticalAlign = 'center';
        openingTeaserLabel.text = Dictionary.getPhrase(ANALYSIS_OPENINGS_TEASER_TEXT);

        var controlTabs = new TabView();
        controlTabs.width = PANEL_WIDTH;
        controlTabs.height = PANEL_HEIGHT;
        controlTabs.addComponent(createTab(ANALYSIS_OVERVIEW_TAB_NAME, overviewTab));
        controlTabs.addComponent(createTab(ANALYSIS_BRANCHES_TAB_NAME, branchingTab, 463));
        controlTabs.addComponent(createTab(ANALYSIS_OPENINGS_TAB_NAME, openingTeaserLabel));

        controlTabs.addEventListener(Event.ADDED_TO_STAGE, onControlTabsAdded);

        return controlTabs;
    }

    private function createTab(phrase:Phrase, component:Component, ?height:Float = 360):Box
    {
        var tab = new Box();
        tab.text = Dictionary.getPhrase(ANALYSIS_OVERVIEW_TAB_NAME);
        tab.width = PANEL_WIDTH - 10;
        tab.height = height;
        tab.addComponent(component);
        return tab;
    }
}