package gfx.analysis;

import gfx.analysis.AnalysisActionBar.BtnPressEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
import gfx.components.Dialogs;
import gfx.analysis.IVariantView.SelectedBranchInfo;
import gameboard.GameBoard.IGameBoardObserver;
import gameboard.GameBoard.GameBoardEvent;
import haxe.ui.core.Component;
import haxe.ui.components.Image;
import struct.Ply;
import gfx.common.MoveNavigator;
import struct.Situation;
import gfx.utils.PlyScrollType;
import struct.Variant;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Box;
import struct.PieceColor;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import dict.Dictionary;
import haxe.ui.containers.Grid;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import gfx.analysis.PosEditMode;
using utils.CallbackTools;

enum RightPanelEvent
{
    BranchSelected(branch:Array<Ply>, startingSituation:Situation, pointer:Int);
    RevertNeeded(plyCnt:Int);
    ClearRequested;
    ResetRequested; //TODO: Situation may be passed as an argument so that GameBoard won't need to keep track of it
    StartPosRequested;
    OrientationChangeRequested; //TODO: Ensure that after the editor is closed everyone knows the correct orientation
    ConstructSituationRequested(situation:Situation);
    TurnColorChanged(newTurnColor:PieceColor);
    ApplyChangesRequested;
    DiscardChangesRequested;
    EditModeChanged(newEditMode:PosEditMode);
    EditorEntered;
    ScrollBtnPressed(type:PlyScrollType);
}

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/right_panel.xml"))
class RightPanel extends HBox implements IGameBoardObserver
{
    private var variantView:IVariantView;

    private var shareCallback:(serializedVariant:String)->Void;
    private var eventHandler:(event:RightPanelEvent)->Void;

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case ContinuationMove(ply, plyStr, performedBy):
                variantView.addChildToSelectedNode(ply, true);
                navigator.writePlyStr(plyStr);
                turnColorStepper.selectedIndex = performedBy == Black? 0 : 1; //If the move that just happened was performed by Black, it's now White to move (and vice-versa)
            case SubsequentMove(plyStr, performedBy):
                turnColorStepper.selectedIndex = performedBy == Black? 0 : 1; //If the move that just happened was performed by Black, it's now White to move (and vice-versa)
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                var plysToRevertCnt = branchLength - plyPointer;
                variantView.addChildToSelectedNode(ply, true);
                navigator.revertPlys(plysToRevertCnt);
                navigator.writePlyStr(plyStr);
                turnColorStepper.selectedIndex = performedBy == Black? 0 : 1; //If the move that just happened was performed by Black, it's now White to move (and vice-versa)
            case SituationEdited(newSituation):
                variantView.clear(newSituation);
            default:
        }
    }

    private function onBranchSelected(branchInfo:SelectedBranchInfo)
    {
        navigator.rewrite(branchInfo.plyStrArray);
        eventHandler(BranchSelected(branchInfo.plyArray, variantView.getStartingSituation(), branchInfo.selectedPlyNum));
    }

    private function onRevertRequestedByBranchingTab(plysToRevert:Int)
    {
        navigator.revertPlys(plysToRevert);
        eventHandler(RevertNeeded(plysToRevert));
    }

    @:bind(applyChangesBtn, MouseEvent.CLICK)
    private function onApplyChangesPressed(e)
    {
        var turnColor:PieceColor = turnColorStepper.selectedIndex == 0? White : Black;
        navigator.clear(turnColor);
        positionEditor.hidden = true;
        controlTabs.hidden = false;
        eventHandler(ApplyChangesRequested);
    }

    @:bind(discardChangesBtn, MouseEvent.CLICK)
    private function onDiscardChangesPressed(e)
    {
        positionEditor.hidden = true;
        controlTabs.hidden = false;
        eventHandler(DiscardChangesRequested);
    }

    @:bind(applySIPBtn, MouseEvent.CLICK)
    private function onApplySIPPressed(e)
    {
        var deserializedSituation:Null<Situation> = Situation.fromSIP(sipInputField.text);
        if (deserializedSituation != null)
        {
            turnColorStepper.selectedIndex = deserializedSituation.turnColor == White? 0 : 1;
            eventHandler(ConstructSituationRequested(deserializedSituation));
        }
        else
            Dialogs.alert("The SIP specified is invalid [P]", "Warning: Invalid SIP");
    }

    private function onActionBarButtonPressed(btnEvent:BtnPressEvent)
    {
        switch btnEvent 
        {
            case ChangeOrientation: 
                eventHandler(OrientationChangeRequested);
            case EditPosition:
                moveModeBtn.selected = true;
                controlTabs.hidden = true;
                positionEditor.hidden = false;
                eventHandler(EditorEntered);
            case Share: 
                shareCallback(variantView.getSerializedVariant());
        }
    }

    @:bind(turnColorStepper, UIEvent.CHANGE)
    private function onTurnColorChanged(e)
    {
        var turnColor:PieceColor = turnColorStepper.selectedIndex == 0? White : Black;
        eventHandler(TurnColorChanged(turnColor));
    }

    public function new(initialVariant:Variant, shareCallback:(serializedVariant:String)->Void, eventHandler:(event:RightPanelEvent)->Void)
    {
        super();
        this.shareCallback = shareCallback;
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

        actionBar.btnCallback = onActionBarButtonPressed;

        navigator.init(initialVariant.startingSituation.turnColor, btn -> {eventHandler(ScrollBtnPressed(btn));});

        branchingHelpLink.onClick = e -> {
            Dialogs.info("Some help here [P]", "Branching Help [P]");
        };

        variantView = switch Preferences.branchingTabType.get() 
        {
            case Tree: new VariantTree(initialVariant);
            case Outline: new VariantTree(initialVariant); //TODO: Change to Outline
            case PlainText: new VariantTree(initialVariant); //TODO: Change to PlainText
        };

        variantView.init(onBranchSelected, onRevertRequestedByBranchingTab);
    }
}