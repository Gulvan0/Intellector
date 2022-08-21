package gfx.screens;

import GlobalBroadcaster;
import gfx.common.PlyHistoryView;
import gfx.analysis.IAnalysisPeripheralEventObserver;
import haxe.Timer;
import haxe.ui.core.Screen as HaxeUIScreen;
import haxe.ui.Toolkit;
import gfx.common.ShareDialog;
import js.Browser;
import gameboard.behaviors.AnalysisBehavior;
import struct.Situation;
import struct.PieceColor;
import gfx.components.BoardWrapper;
import haxe.ui.core.Component;
import struct.Variant;
import gameboard.GameBoard;
import gfx.analysis.ControlTabs;
import gfx.analysis.PositionEditor;
import gameboard.GameBoard.IGameBoardObserver;
import gfx.analysis.PeripheralEvent;
import haxe.ui.containers.HBox;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/analysis/analysis_layout.xml'))
class Analysis extends Screen implements IGameBoardObserver implements IGlobalEventObserver
{
    private var variant:Variant;

    private var board:GameBoard;
    private var positionEditor:PositionEditor;
    private var controlTabs:ControlTabs;

    private var boardWrapper:BoardWrapper;

    private var analysisPeripheryObservers:Array<IAnalysisPeripheralEventObserver>;
    private var gameboardObservers:Array<IGameBoardObserver>;
    private var plyHistoryViews:Array<PlyHistoryView>;

    public function onEnter()
    {
        GlobalBroadcaster.addObserver(this);
    }

    public function onClose()
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        board.handleGlobalEvent(event);

        switch event 
        {
            case PreferenceUpdated(Markup):
                boardContainer.invalidateComponentLayout(true);
            case PreferenceUpdated(BranchingType):
                controlTabs.redrawBranchingTab(variant);
            case PreferenceUpdated(BranchingShowTurnColor):
                if (controlTabs.branchingTabType == Tree)
                    controlTabs.redrawBranchingTab(variant);
            default:
        }
    }

    private function redrawPositionEditor()
    {
        positionEditor.updateLayout(positionEditorContainer.width, HaxeUIScreen.instance.height * 0.3);
    }

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = HaxeUIScreen.instance.width / HaxeUIScreen.instance.height < 1.2;
        var wasCompact:Bool = lControlTabsContainer.hidden;

        cCreepingLineContainer.hidden = !compact;
        cActionBarContainer.hidden = !compact;
        lControlTabsContainer.hidden = compact;

        var parentChanged:Bool = super.validateComponentLayout();

        Timer.delay(redrawPositionEditor, 100);

        return parentChanged || wasCompact != compact;
    }

    private function displayShareDialog()
    {
        var serializedVariant:String = variant.serialize();

        var exportNewCallback:String->Void = name -> {
            Networker.emitEvent(SetStudy(name, serializedVariant, null));
        };

        var overwriteCallback:Int->String->Void = (id:Int, name:String) -> {
            Networker.emitEvent(SetStudy(name, serializedVariant, id));
        };

        var shareDialog:ShareDialog = new ShareDialog();
        switch ScreenManager.getCurrentScreenType()
        {
            case Analysis(_, _, exploredStudyID, exploredStudyName):
                if (exploredStudyID != null)
                    shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, exportNewCallback, overwriteCallback.bind(exploredStudyID), exploredStudyName);
                else
                    shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, exportNewCallback);
            default:
                throw "ShareRequested happened outside of Analysis screen!";
        }
        
        shareDialog.showShareDialog(board);
    }

    private function handlePeripheralEvent(event:PeripheralEvent)
    {
        for (obs in analysisPeripheryObservers)
            obs.handleAnalysisPeripheralEvent(event);

        if (event.match(ShareRequested))
            displayShareDialog();
        else if (event.match(ApplyChangesRequested))
        {
            for (view in plyHistoryViews)
                view.updateStartingSituation(board.startingSituation);
            controlTabs.clearBranching(board.startingSituation);
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        for (obs in gameboardObservers)
            obs.handleGameBoardEvent(event);
    }

    private override function onReady()
    {
        super.onReady();
        redrawPositionEditor();
    }

    public function new(?initialVariantStr:String, ?selectedMainlineMove:Int)
    {
        super();
        customEnterHandler = onEnter;
        customCloseHandler = onClose;

        variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.starting());

        board = new GameBoard(Analysis(variant));
        controlTabs = new ControlTabs(variant, handlePeripheralEvent);
        positionEditor = new PositionEditor(handlePeripheralEvent);
        positionEditor.hidden = true;

        analysisPeripheryObservers = [board, controlTabs, controlTabs.navigator, positionEditor, creepingLine, actionBar];
        gameboardObservers = [controlTabs, controlTabs.navigator, positionEditor, creepingLine];
        plyHistoryViews = [controlTabs.navigator, creepingLine];

        for (view in plyHistoryViews)
            view.init(type -> {handlePeripheralEvent(ScrollBtnPressed(type));}, Analysis(variant));

        actionBar.eventHandler = handlePeripheralEvent;
        
        boardWrapper = new BoardWrapper(board);
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';

        boardContainer.addComponent(boardWrapper);
        lControlTabsContainer.addComponent(controlTabs);
        positionEditorContainer.addComponent(positionEditor);

        board.addObserver(this);

        if (selectedMainlineMove != null)
            handlePeripheralEvent(ScrollBtnPressed(Precise(selectedMainlineMove)));
    }
}