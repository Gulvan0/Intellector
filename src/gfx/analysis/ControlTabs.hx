package gfx.analysis;

import haxe.ui.events.MouseEvent;
import gfx.popups.BranchingHelp;
import net.shared.board.Situation;
import gameboard.GameBoard.IGameBoardObserver;
import Preferences.BranchingTabType;
import haxe.ui.core.Screen;
import haxe.ui.containers.dialogs.MessageBox;
import haxe.ui.events.UIEvent;
import gfx.Dialogs;
import gameboard.GameBoard.GameBoardEvent;
import haxe.ui.core.Component;
import haxe.ui.components.Image;
import gfx.common.MoveNavigator;
import gfx.utils.PlyScrollType;
import struct.Variant;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Box;
import net.shared.PieceColor;
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

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/analysis/control_tabs.xml"))
class ControlTabs extends TabView implements IGameBoardObserver implements IAnalysisPeripheralEventObserver
{
    public var branchingTabType(default, null):BranchingTabType;

    private var variantView:IVariantView;
    private var eventHandler:PeripheralEvent->Void;

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case ScrollBtnPressed(type):
                variantView.handlePlyScrolling(type);
            case ApplyChangesRequested:
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
            case BranchingMove(ply, _, _, _):
                variantView.addChildToSelectedNode(ply, true);
            default:
        }
    }

    public function clearBranching(?newStartingSituation:Situation)
    {
        variantView.clear(newStartingSituation);
    }

    private function onWheel(tree:VariantTree, e:MouseEvent)
    {
        if (e.ctrlKey) 
        {
            e.cancel();
            if (e.delta > 0 && tree.scale < 8)
                tree.setScale(tree.scale * 2);
            else if (e.delta < 0 && tree.scale > 0.125)
                tree.setScale(tree.scale / 2);
        } 
    }

    public function redrawBranchingTab(variant:Variant)
    {
        var selectedNode:VariantPath = variantView.getSelectedNode();

        switch branchingTabType 
        {
            case Tree, PlainText:
                variantViewSV.removeAllComponents();
            case Outline:
                branchingTabContentsBox.removeComponentAt(2);
        }
        drawBranchingTab(variant, selectedNode);
    }

    private function drawBranchingTab(initialVariant:Variant, ?selectedNode:VariantPath)
    {
        branchingTabType = Preferences.branchingTabType.get();
        switch branchingTabType
        {
            case Tree: 
                var tree:VariantTree = new VariantTree(initialVariant, selectedNode);
                variantView = tree;
                variantViewSV.hidden = false;
                variantViewSV.percentContentWidth = null;
                variantViewSV.addComponent(tree);
                variantViewSV.registerEvent(MouseEvent.MOUSE_WHEEL, onWheel.bind(tree), 100);
                onChange = e -> {
                    if (selectedPage == branchingTab)
                        tree.refreshLayout();
                };
                tree.refreshLayout();
            case Outline: 
                var comp:VariantOutline = new VariantOutline(initialVariant, selectedNode);
                variantView = comp;
                variantViewSV.hidden = true;
                variantViewSV.percentContentWidth = null;
                branchingTabContentsBox.addComponent(comp);
                onChange = e -> {
                    if (selectedPage == branchingTab)
                        comp.refreshSelection();
                };
            case PlainText: 
                var box:VariantPlainText = new VariantPlainText(initialVariant, selectedNode);
                variantView = box;
                variantViewSV.hidden = false;
                variantViewSV.percentContentWidth = 100;
                variantViewSV.addComponent(box);
                onChange = null;
        };
        variantView.init(eventHandler);
    }

    public function new(initialVariant:Variant, eventHandler:PeripheralEvent->Void)
    {
        super();

        this.eventHandler = eventHandler;
        actionBar.init(false, eventHandler);

        branchingHelpLink.onClick = e -> {
            Dialogs.getQueue().addBasic(new BranchingHelp(), null, true);
        };

        drawBranchingTab(initialVariant);
    }
}