package gfx.analysis;

import gameboard.GameBoard.IGameBoardObserver;
import gameboard.Piece;
import utils.AssetManager;
import haxe.ui.util.Variant;
import haxe.ui.components.Image;
import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;
import gfx.Dialogs;
import gameboard.GameBoard.GameBoardEvent;
import struct.Situation;
import struct.PieceColor;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/position_editor.xml"))
class PositionEditor extends VBox implements IGameBoardObserver implements IAnalysisPeripheralEventObserver
{
    private var eventHandler:PeripheralEvent->Void;

    private var renderedForWidth:Float;
    private var renderedForHeight:Float;

    private var editModeBtns:Map<PosEditMode, Button>;
    private var toolBtns:Array<Button>;

    private function getTurnColor():PieceColor
    {
        return turnColorStepper.selectedIndex == 0? White : Black;
    }

    private function setTurnColor(color:PieceColor)
    {
        turnColorStepper.selectedIndex = color == White? 0 : 1;
    }

    public function updateLayout(availableWidth:Float, availableHeight:Float):Bool
    {
        if (renderedForWidth == availableWidth && renderedForHeight == availableHeight)
            return false;

        var spacing:Float = 5;
        var padding:Float = 10;
        var wideModeBtnHeight:Float = (availableWidth - spacing * (7 - 1)) / 7;
        var wideModeFullHeight:Float = wideModeBtnHeight * 4 + spacing * (4 - 1) + padding * 2;

        var btnSide:Float = wideModeFullHeight <= availableHeight? wideModeBtnHeight : (availableHeight - spacing * (4 - 1) - padding * 2) / 4;

        for (mode => btn in editModeBtns)
        {
            var icon:Image = btn.findComponent(Image);
            var iconMaxSide:Float = 0.7 * btnSide;

            btn.width = btnSide;
            btn.height = btnSide;

            switch mode 
            {
                case Move, Delete:
                    icon.width = iconMaxSide;
                    icon.height = iconMaxSide;
                case Set(Progressor, color):
                    icon.width = Piece.pieceRelativeScale(Progressor) * iconMaxSide;
                    icon.height = icon.width / Piece.pieceAspectRatio(Progressor, color);
                case Set(type, color):
                    icon.height = Piece.pieceRelativeScale(type) * iconMaxSide;
                    icon.width = icon.height * Piece.pieceAspectRatio(type, color);
            }
        }

        var additionalRowHeight:Float = btnSide * 0.8;

        for (btn in toolBtns)
        {
            var icon:Image = btn.findComponent(Image);

            btn.width = additionalRowHeight;
            btn.height = additionalRowHeight;
            icon.width = additionalRowHeight;
            icon.height = additionalRowHeight;
        }

        otherOptionsHBox.width = btnSide * 7 + spacing * (7 - 1);
        turnColorStepper.customStyle = {fontSize: additionalRowHeight / 3, textAlign: 'center'};
        applyChangesBtn.customStyle = {fontSize: additionalRowHeight / 2};
        discardChangesBtn.customStyle = {fontSize: additionalRowHeight / 2};

        return true;
    }

    @:bind(importBtn, MouseEvent.CLICK)
    private function onImportSIPPressed(e)
    {
        var deserializedSituation:Null<Situation> = null;
        var response:Null<String> = Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_INPUT_SIP_PROMPT_TEXT));
        if (response != null)
            deserializedSituation = Situation.fromSIP(response);
       
        if (deserializedSituation != null)
        {
            setTurnColor(deserializedSituation.turnColor);
            eventHandler(ConstructSituationRequested(deserializedSituation));
        }
        else
            Dialogs.alert(ANALYSIS_INVALID_SIP_WARNING_TEXT, ANALYSIS_INVALID_SIP_WARNING_TITLE);
    }

    @:bind(turnColorStepper, UIEvent.CHANGE)
    private function onTurnColorChanged(e)
    {
        eventHandler(TurnColorChanged(getTurnColor()));
    }

    @:bind(applyChangesBtn, MouseEvent.CLICK)
    private function onApplyChangesPressed(e)
    {
        hidden = true;
        eventHandler(ApplyChangesRequested);
    }

    @:bind(discardChangesBtn, MouseEvent.CLICK)
    private function onDiscardChangesPressed(e)
    {
        hidden = true;
        eventHandler(DiscardChangesRequested);
    }

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case EditorLaunchRequested:
                moveModeBtn.selected = true;
                hidden = false;
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case ContinuationMove(_, _, performedBy):
                setTurnColor(opposite(performedBy));
            case SubsequentMove(_, performedBy):
                setTurnColor(opposite(performedBy));
            case BranchingMove(_, _, performedBy, _):
                setTurnColor(opposite(performedBy));
        }
    }

    public function new(eventHandler:PeripheralEvent->Void)
    {
        super();
        this.eventHandler = eventHandler;

        editModeBtns = [
            Move => moveModeBtn,
            Set(Progressor, White) => setProgWhiteModeBtn,
            Set(Aggressor, White) => setAgrWhiteModeBtn,
            Set(Defensor, White) => setDefWhiteModeBtn,
            Set(Liberator, White) => setLibWhiteModeBtn,
            Set(Dominator, White) => setDomWhiteModeBtn,
            Set(Intellector, White) => setIntWhiteModeBtn,
            Delete => deleteModeBtn,
            Set(Progressor, Black) => setProgBlackModeBtn,
            Set(Aggressor, Black) => setAgrBlackModeBtn,
            Set(Defensor, Black) => setDefBlackModeBtn,
            Set(Liberator, Black) => setLibBlackModeBtn,
            Set(Dominator, Black) => setDomBlackModeBtn,
            Set(Intellector, Black) => setIntBlackModeBtn
        ];
        toolBtns = [orientationBtn, importBtn, clearBtn, resetBtn, startBtn];

        for (mode => btn in editModeBtns)
            btn.onClick = e -> {eventHandler(EditModeChanged(mode));};

        clearBtn.onClick = e -> {eventHandler(ClearRequested);};
        resetBtn.onClick = e -> {eventHandler(ResetRequested);};
        startBtn.onClick = e -> {eventHandler(StartPosRequested);};
        orientationBtn.onClick = e -> {eventHandler(OrientationChangeRequested);};
    }
}