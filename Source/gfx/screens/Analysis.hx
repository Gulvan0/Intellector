package gfx.screens;

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

    //TODO: Add importBtn SVG icon

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = Browser.window.innerWidth / Browser.window.innerHeight < 1.2;

        cCreepingLineContainer.hidden = !compact;
        cActionBarContainer.hidden = !compact;
        lControlTabsContainer.hidden = compact;

        return super.validateComponentLayout();
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
        board.handlePeripheralEvent(event);
        controlTabs.handlePeripheralEvent(event);
        positionEditor.handlePeripheralEvent(event);
        creepingLine.handlePeripheralEvent(event);

        if (event == ShareRequested)
            displayShareDialog();
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        controlTabs.handleGameBoardEvent(event);
        positionEditor.handleGameBoardEvent(event);
        creepingLine.handlePeripheralEvent(event);
    }

    public function new(?initialVariantStr:String)
    {
        super();

        var initialVariant:Variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.starting());
        var startingSituation:Situation = initialVariant.startingSituation;
        var firstColorToMove:PieceColor = startingSituation.turnColor;

        board = new GameBoard(startingSituation, firstColorToMove, new AnalysisBehavior(firstColorToMove), false);
        controlTabs = new ControlTabs(initialVariant, handlePeripheralEvent);
        positionEditor = new PositionEditor(handlePeripheralEvent);

        creepingLine.init(i -> {handlePeripheralEvent(PlySelected(i));}, firstColorToMove);
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