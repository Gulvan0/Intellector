package gfx.analysis;

import haxe.ui.core.Screen;
import openfl.events.MouseEvent;
import openfl.display.DisplayObject;
import haxe.ui.containers.dialogs.MessageBox;
import gfx.components.SpriteWrapper;
import haxe.ui.events.UIEvent;
import gfx.components.Dialogs;
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
class ControlTabs extends TabView implements IGameBoardObserver implements IAnalysisPeripheralEventObserver
{
    private var variantView:IVariantView;

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

    private function onWheel(obj:DisplayObject, e:MouseEvent)
    {
        if (e.ctrlKey)
        {
            e.preventDefault();
            e.stopPropagation();
            if (e.delta > 0 && obj.scaleX < 8)
            {
                obj.scaleX *= 2;
                obj.scaleY *= 2;
            }
            else if (e.delta < 0 && obj.scaleX > 0.125)
            {
                obj.scaleX /= 2;
                obj.scaleY /= 2;
            }
        } 
    }

    public function new(initialVariant:Variant, eventHandler:PeripheralEvent->Void)
    {
        super();

        actionBar.eventHandler = eventHandler;

        branchingHelpLink.onClick = e -> {
            Dialogs.branchingHelp();
        };

        switch Preferences.branchingTabType.get() 
        {
            case Tree: 
                var tree:VariantTree = new VariantTree(initialVariant);
                variantView = tree;
                variantViewSV.hidden = false;
                variantViewSV.addComponent(new SpriteWrapper(tree, false));
                variantViewSV.addEventListener(MouseEvent.MOUSE_WHEEL, onWheel.bind(tree), false, 100);
                onChange = e -> {
                    if (selectedPage == branchingTab)
                        tree.refreshLayout();
                };
            case Outline: 
                var comp:VariantOutline = new VariantOutline(initialVariant);
                variantView = comp;
                variantViewSV.hidden = true;
                branchingTabContentsBox.addComponent(comp);
            case PlainText: 
                var box:VariantPlainText = new VariantPlainText(initialVariant);
                variantView = box;
                variantViewSV.hidden = false;
                variantViewSV.percentContentWidth = 100;
                variantViewSV.addComponent(box);
        };
        variantView.init(eventHandler);
    }
}