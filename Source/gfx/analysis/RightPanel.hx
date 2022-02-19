package gfx.analysis;

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
import analysis.AlphaBeta;
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
    BranchSelected(branch:Array<Ply>, startingSituation:Situation);
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
    AnalyzePressed(color:PieceColor);
    ExportSIPRequested;
    ExportStudyRequested(variant:Variant);
    InitializationFinished;
}

interface RightPanelObserver
{
    public function handleRightPanelEvent(event:RightPanelEvent):Void;    
}

class RightPanel extends Sprite
{
    private static var PANEL_WIDTH = 400;
    private static var PANEL_HEIGHT = 500;

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
            case AnalyzePressed(color):
                overviewTab.displayLoadingOnScoreLabel();
                emit(AnalyzePressed(color));
            case ExportSIPRequested:
                emit(ExportSIPRequested);
            case ExportStudyRequested:
                emit(ExportStudyRequested(branchingTab.variant));
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
            case BranchSelected(branch, plyStrArray, startingSituation):
                overviewTab.deprecateScore();
                overviewTab.navigator.clear();
                var color:PieceColor = startingSituation.turnColor;
                for (plyStr in plyStrArray)
                {
                    overviewTab.navigator.writePlyStr(plyStr, color);
                    color = opposite(color);
                }
                emit(BranchSelected(branch, startingSituation));
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
                overviewTab.clearAnalysisScore();
                emit(ClearRequested);
            case ResetPressed:
                overviewTab.clearAnalysisScore();
                emit(ResetRequested);
            case ConstructFromSIPPressed(sip):
                var situation:Situation = SituationDeserializer.deserialize(sip);
                positionEditor.changeColorOptions(situation.turnColor);
                emit(ConstructSituationRequested(situation));
            case TurnColorChanged(newTurnColor):
                emit(TurnColorChanged(newTurnColor));
            case ApplyChangesPressed:
                overviewTab.navigator.clear();
                overviewTab.deprecateScore();
                showControlTabs();
                emit(ApplyChangesPressed);
            case DiscardChangesPressed:
                showControlTabs();
                emit(DiscardChangesPressed);
            case EditModeChanged(newEditMode):
                emit(EditModeChanged(newEditMode));
        }
    }

    private function handleGameboardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case SituationEdited(newSituation):
                branchingTab.variant = new Variant(newSituation.copy());
                branchingTab.variantView.clear();
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

    public function new(startingSituation:Situation) 
    {
        super();

        positionEditor = new PositionEditor();
        controlTabs = createControlTabs(startingSituation);
        
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
        branchingTab = new BranchingTab(Preferences.instance.branchingTabType, startingSituation, 390, 360);

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
        tab.addComponent(overviewVBox);
        return tab;
    }
}