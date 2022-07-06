package gfx.analysis;

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

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/analysis/control_tabs.xml"))
class ControlTabs extends TabView
{
    private var variantView:IVariantView;

    private var eventHandler:PeripheralEvent->Void;

    public function handlePeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case ApplyChangesRequested(turnColor):
                navigator.clear(turnColor);
                disabled = false;
            case DiscardChangesRequested:
                disabled = false;
            case EditorLaunchRequested:
                disabled = true;
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event
        {
            case ContinuationMove(ply, plyStr, performedBy):
                variantView.addChildToSelectedNode(ply, true);
                navigator.writePlyStr(plyStr);
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                var plysToRevertCnt = branchLength - plyPointer;
                variantView.addChildToSelectedNode(ply, true);
                navigator.revertPlys(plysToRevertCnt);
                navigator.writePlyStr(plyStr);
            case SituationEdited(newSituation):
                variantView.clear(newSituation);
            default:
        }
    }

    private function onBranchSelected(branchInfo:SelectedBranchInfo)
    {
        navigator.rewrite(branchInfo.plyStrArray);
        eventHandler(BranchSelected(branchInfo.plyArray, branchInfo.plyStrArray, branchInfo.selectedPlyNum));
    }

    private function onRevertRequestedByBranchingTab(plysToRevert:Int)
    {
        navigator.revertPlys(plysToRevert);
        eventHandler(RevertNeeded(plysToRevert));
    }

    public function new(initialVariant:Variant, eventHandler:PeripheralEvent->Void)
    {
        super();
        this.eventHandler = eventHandler;

        actionBar.eventHandler = eventHandler;

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
        variantViewSV.addComponent(variantView);
    }
}