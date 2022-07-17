package gfx.screens;

import haxe.ui.core.Screen;
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
class Analysis extends HBox implements IScreen implements IGameBoardObserver
{
    private var variant:Variant;

    private var board:GameBoard;
    private var positionEditor:PositionEditor;
    private var controlTabs:ControlTabs;

    public function onEntered()
    {
        //* Do nothing
    }

    public function onClosed()
    {
        //* Do nothing
    }

    public function menuHidden():Bool
    {
        return false;
    }

    public function asComponent():Component
    {
        return this;
    }

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = Screen.instance.width / Screen.instance.height < 1.2;
        var wasCompact:Bool = lControlTabsContainer.hidden;

        cCreepingLineContainer.hidden = !compact;
        cActionBarContainer.hidden = !compact;
        lControlTabsContainer.hidden = compact;

        return super.validateComponentLayout() || wasCompact != compact;
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
        switch ScreenManager.currentScreenType 
        {
            case Analysis(_, exploredStudyID, exploredStudyName):
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
        board.handleAnalysisPeripheralEvent(event);
        controlTabs.handlePeripheralEvent(event);
        positionEditor.handlePeripheralEvent(event);
        creepingLine.handlePeripheralEvent(event);
        actionBar.handlePeripheralEvent(event);

        if (event.match(ShareRequested))
            displayShareDialog();
        else if (event.match(ApplyChangesRequested(_)))
            controlTabs.clearBranching(board.startingSituation);
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        controlTabs.handleGameBoardEvent(event);
        positionEditor.handleGameBoardEvent(event);
        creepingLine.handleGameBoardEvent(event);
    }

    public function new(?initialVariantStr:String)
    {
        super();

        variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.starting());
        var startingSituation:Situation = variant.startingSituation;
        var firstColorToMove:PieceColor = startingSituation.turnColor;

        board = new GameBoard(startingSituation, firstColorToMove, new AnalysisBehavior(), false);
        controlTabs = new ControlTabs(variant, handlePeripheralEvent);
        positionEditor = new PositionEditor(handlePeripheralEvent);
        positionEditor.hidden = true;

        creepingLine.init(i -> {handlePeripheralEvent(ScrollBtnPressed(Precise(i)));}, firstColorToMove);
        actionBar.eventHandler = handlePeripheralEvent;
        
        var boardWrapper:BoardWrapper = new BoardWrapper(board);
        boardWrapper.percentHeight = 100;
        boardWrapper.maxPercentWidth = 100;
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';

        boardContainer.addComponent(boardWrapper);
        lControlTabsContainer.addComponent(controlTabs);
        positionEditorContainer.addComponent(positionEditor);
        
        board.addObserver(this);
    }
}