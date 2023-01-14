package gfx.screens;

import gfx.popups.ChallengeParamsDialog;
import struct.ChallengeParams;
import GlobalBroadcaster;
import gfx.common.PlyHistoryView;
import gfx.analysis.IAnalysisPeripheralEventObserver;
import haxe.Timer;
import haxe.ui.core.Screen as HaxeUIScreen;
import haxe.ui.Toolkit;
import gfx.common.ShareDialog;
import js.Browser;
import gameboard.behaviors.AnalysisBehavior;
import net.shared.PieceColor;
import haxe.ui.core.Component;
import struct.Variant;
import gameboard.GameBoard;
import gfx.analysis.ControlTabs;
import gfx.analysis.PositionEditor;
import gameboard.GameBoard.IGameBoardObserver;
import gfx.analysis.PeripheralEvent;
import haxe.ui.containers.HBox;
import net.shared.board.Situation;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/analysis/analysis_layout.xml'))
class Analysis extends Screen implements IGameBoardObserver implements IGlobalEventObserver
{
    private var variant:Variant;

    private var board:GameBoard;
    private var positionEditor:PositionEditor;
    private var controlTabs:ControlTabs;

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
            case LoggedIn:
                actionBar.playFromPosBtn.disabled = false;
            case LoggedOut:
                actionBar.playFromPosBtn.disabled = true;
            case PreferenceUpdated(Marking):
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
        positionEditor.updateLayout(positionEditorContainer.width, HaxeUIScreen.instance.actualHeight * 0.3);
    }

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = HaxeUIScreen.instance.actualWidth / HaxeUIScreen.instance.actualHeight < 1.2;
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
        var shareDialog:ShareDialog = new ShareDialog();
        switch SceneManager.getCurrentScreenType()
        {
            case Analysis(_, _, exploredStudyData):
                shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, variant, exploredStudyData);
            default:
                throw "ShareRequested happened outside of Analysis screen!";
        }
        
        shareDialog.showShareDialog(board);
    }

    private function handlePeripheralEvent(event:PeripheralEvent)
    {
        if (!Networker.isConnectedToServer() && event.match(PlayFromHereRequested))
            return;

        for (obs in analysisPeripheryObservers)
            obs.handleAnalysisPeripheralEvent(event);

        if (event.match(ShareRequested))
            displayShareDialog();
        else if (event.match(PlayFromHereRequested))
            Dialogs.getQueue().add(new ChallengeParamsDialog(ChallengeParams.playFromPosParams(board.shownSituation), true));
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
        if (positionEditor.isReady)
            redrawPositionEditor();
        else
            positionEditor.customReadyHandler = redrawPositionEditor;
    }

    public function new(?initialVariantStr:String, ?selectedMainlineMove:Int)
    {
        super();
        customEnterHandler = onEnter;
        customCloseHandler = onClose;

        variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.defaultStarting());

        board = new GameBoard(Analysis(variant));
        board.percentHeight = 100;
        board.percentWidth = 100;

        controlTabs = new ControlTabs(variant, handlePeripheralEvent);
        positionEditor = new PositionEditor(handlePeripheralEvent);
        positionEditor.hidden = true;

        analysisPeripheryObservers = [board, controlTabs, controlTabs.navigator, positionEditor, creepingLine, actionBar];
        gameboardObservers = [controlTabs, controlTabs.navigator, positionEditor, creepingLine];
        plyHistoryViews = [controlTabs.navigator, creepingLine];

        for (view in plyHistoryViews)
            view.init(type -> {handlePeripheralEvent(ScrollBtnPressed(type));}, Analysis(variant));

        actionBar.init(true, handlePeripheralEvent);

        boardContainer.addComponent(board);
        lControlTabsContainer.addComponent(controlTabs);
        positionEditorContainer.addComponent(positionEditor);

        board.addObserver(this);

        if (selectedMainlineMove != null)
            handlePeripheralEvent(ScrollBtnPressed(Precise(selectedMainlineMove)));
    }
}