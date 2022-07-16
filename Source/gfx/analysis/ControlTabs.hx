package gfx.analysis;

import haxe.ui.containers.dialogs.MessageBox;
import gfx.components.SpriteWrapper;
import haxe.ui.events.UIEvent;
import haxe.ui.events.MouseEvent;
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
class ControlTabs extends TabView
{
    private var variantView:IVariantView;

    private var eventHandler:PeripheralEvent->Void;

    public function handlePeripheralEvent(event:PeripheralEvent)
    {
        navigator.handlePeripheralEvent(event);
        switch event 
        {
            case ApplyChangesRequested(turnColor):
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
        navigator.handleGameBoardEvent(event);
        switch event
        {
            case ContinuationMove(ply, plyStr, performedBy):
                variantView.addChildToSelectedNode(ply, true);
            case BranchingMove(ply, plyStr, performedBy, plyPointer, branchLength):
                variantView.addChildToSelectedNode(ply, true);
            default:
        }
    }

    public function clearBranching(?newStartingSituation:Situation)
    {
        variantView.clear(newStartingSituation);
    }

    public function new(initialVariant:Variant, eventHandler:PeripheralEvent->Void)
    {
        super();
        this.eventHandler = eventHandler;

        actionBar.eventHandler = eventHandler;

        navigator.init(initialVariant.startingSituation.turnColor, btn -> {eventHandler(ScrollBtnPressed(btn));});

        branchingHelpLink.onClick = e -> {
            var messageBox = new MessageBox();
            messageBox.type = MessageBoxType.TYPE_INFO;
            messageBox.title = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TITLE);
            messageBox.messageLabel.htmlText = Dictionary.getPhrase(ANALYSIS_BRANCHING_HELP_DIALOG_TEXT);
            messageBox.messageLabel.customStyle = {fontSize: 18};
            messageBox.width = 500;
            messageBox.modal = true;
            messageBox.show();
        };

        var variantViewWrapper:SpriteWrapper = null;

        switch Preferences.branchingTabType.get() 
        {
            case Tree: 
                var tree:VariantTree = new VariantTree(initialVariant);
                variantViewWrapper = new SpriteWrapper(tree, false);
                variantView = tree;
            case Outline: 
                //TODO:
            case PlainText: 
                //TODO:
        };

        variantView.init(eventHandler);

        variantViewSV.addComponent(variantViewWrapper);
    }
}