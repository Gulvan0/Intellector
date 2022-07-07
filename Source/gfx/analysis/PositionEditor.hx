package gfx.analysis;

import haxe.ui.events.UIEvent;
import gfx.components.Dialogs;
import gameboard.GameBoard.GameBoardEvent;
import struct.Situation;
import struct.PieceColor;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/position_editor.xml"))
class PositionEditor extends VBox
{
    private var eventHandler:PeripheralEvent->Void;

    private function getTurnColor():PieceColor
    {
        return turnColorStepper.selectedIndex == 0? White : Black;
    }

    private function setTurnColor(color:PieceColor)
    {
        turnColorStepper.selectedIndex = color == White? 0 : 1;
    }

    @:bind(importBtn, MouseEvent.CLICK)
    private function onImportSIPPressed(e)
    {
        var deserializedSituation:Null<Situation> = null;
        var response:Null<String> = Browser.window.prompt("Input SIP [P]");
        if (response != null)
            deserializedSituation = Situation.fromSIP(response);
       
        if (deserializedSituation != null)
        {
            setTurnColor(deserializedSituation.turnColor);
            eventHandler(ConstructSituationRequested(deserializedSituation));
        }
        else
            Dialogs.alert("The SIP specified is invalid [P]", "Warning: Invalid SIP [P]");
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
        eventHandler(ApplyChangesRequested(getTurnColor()));
    }

    @:bind(discardChangesBtn, MouseEvent.CLICK)
    private function onDiscardChangesPressed(e)
    {
        hidden = true;
        eventHandler(DiscardChangesRequested);
    }

    public function handlePeripheralEvent(event:PeripheralEvent)
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
            case BranchingMove(_, _, performedBy, _, _):
                setTurnColor(opposite(performedBy));
            default:
        }
    }

    public function new(eventHandler:PeripheralEvent->Void)
    {
        super();
        this.eventHandler = eventHandler;

        moveModeBtn.onClick = e -> {eventHandler(EditModeChanged(Move));};
        setProgWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Progressor, White)));};
        setAgrWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Aggressor, White)));};
        setDefWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Defensor, White)));};
        setLibWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Liberator, White)));};
        setDomWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Dominator, White)));};
        setIntWhiteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Intellector, White)));};
        deleteModeBtn.onClick = e -> {eventHandler(EditModeChanged(Delete));};
        setProgBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Progressor, Black)));};
        setAgrBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Aggressor, Black)));};
        setDefBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Defensor, Black)));};
        setLibBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Liberator, Black)));};
        setDomBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Dominator, Black)));};
        setIntBlackModeBtn.onClick = e -> {eventHandler(EditModeChanged(Set(Intellector, Black)));};

        clearBtn.onClick = e -> {eventHandler(ClearRequested);};
        resetBtn.onClick = e -> {eventHandler(ResetRequested);};
        startBtn.onClick = e -> {eventHandler(StartPosRequested);};
        orientationBtn.onClick = e -> {eventHandler(OrientationChangeRequested);};
    }
}