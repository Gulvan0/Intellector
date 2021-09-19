package gfx.components.analysis;

import struct.Variant;
import haxe.ui.containers.ScrollView;
import haxe.ui.containers.Box;
import haxe.ui.components.OptionBox;
import struct.PieceColor;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import dict.Dictionary;
import haxe.ui.containers.Grid;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;
import gfx.components.analysis.PosEditMode;

class RightPanel extends Sprite
{
    private static var PANEL_WIDTH = 400;
    private static var PANEL_HEIGHT = 500;

    private var positionSetupBox:VBox;
    private var controlTabs:TabView;
    private var pressedEditModeBtn:Button;

    private var variantTree:VariantTree;

    private var onModeChanged:PosEditMode->Void;
    private var onClear:Void->Void;
    private var onReset:Void->Void;
    private var onSIPPromted:String->Void;
    private var onTurnColorChanged:PieceColor->Void;
    private var onApplyChanges:Void->Void;
    private var onDiscardChanges:Void->Void;
    private var onBranchSelected:String->Void;

    private function showPositionEditor() 
    {
        controlTabs.visible = false;
        positionSetupBox.visible = true;
    }

    private function showControlTabs() 
    {
        positionSetupBox.visible = false;
        controlTabs.visible = true;
    }

    public function initVariant(variant:Variant)
    {
        variantTree.init(variant);
    }

    public function new() 
    {
        super();

        createPositionEditor();
        createControlTabs();
        
        var fullBox:HBox = new HBox();
        fullBox.addComponent(positionSetupBox);
        fullBox.addComponent(controlTabs);
        addChild(fullBox);
    }

    private function createPositionEditor() 
    {
        var editModeButtons:Grid = new Grid();
        editModeButtons.horizontalAlign = 'center';
        editModeButtons.columns = 7;
        for (mode in [Move, Set(Progressor, White), Set(Aggressor, White), Set(Liberator, White), Set(Defensor, White), Set(Dominator, White), Set(Intellector, White), Delete, Set(Progressor, Black), Set(Aggressor, Black), Set(Liberator, Black), Set(Defensor, Black), Set(Dominator, Black), Set(Intellector, Black)])
            editModeButtons.addComponent(constructButton(mode));

        var clearButton:Button = new Button();
        clearButton.horizontalAlign = 'center';
        clearButton.width = 100;
        clearButton.text = Dictionary.getPhrase(ANALYSIS_CLEAR);
        clearButton.onClick = e -> {onClear();};

        var resetButton:Button = new Button();
        resetButton.horizontalAlign = 'center';
        resetButton.width = 100;
        resetButton.text = Dictionary.getPhrase(ANALYSIS_RESET);
        resetButton.onClick = e -> {onReset();};

        var turnColorSelectBox:HBox = new HBox();
        turnColorSelectBox.horizontalAlign = 'center';

        for (color in PieceColor.createAll())
        {
            var optionBox:OptionBox = new OptionBox();
            optionBox.text = Dictionary.getAnalysisTurnColorSelectLabel(color);
            optionBox.componentGroup = "analysis-editor-turncolor";
            optionBox.onChange = (e) -> {
                if (optionBox.selected)
                    onTurnColorChanged(color);
            };
            if (color == White)
                optionBox.selected = true;
            turnColorSelectBox.addComponent(optionBox);
        }    

        var specialEditButtons:HBox = new HBox();
        specialEditButtons.horizontalAlign = 'center';
        specialEditButtons.width = 300;
        specialEditButtons.addComponent(clearButton);
        specialEditButtons.addComponent(resetButton);

        var fromSIPLabel:Label = new Label();
        fromSIPLabel.horizontalAlign = 'left';
        fromSIPLabel.text = "From SIP:";
        fromSIPLabel.customStyle = {fontSize: 20, fontItalic: true};

        var fromSIPInput:TextField = new TextField();
        fromSIPInput.width = 340;

        var fromSIPApplyBtn:Button = new Button();
        clearButton.width = 50;
        clearButton.text = Dictionary.getPhrase(ANALYSIS_APPLY);
        clearButton.onClick = e -> {onSIPPromted(fromSIPInput.text);};

        var SIPInputBox:HBox = new HBox();
        clearButton.horizontalAlign = 'left';
        SIPInputBox.addComponent(fromSIPInput);
        SIPInputBox.addComponent(fromSIPApplyBtn);

        var applyChagesBtn:Button = new Button();
        applyChagesBtn.horizontalAlign = 'center';
        applyChagesBtn.width = 150;
        applyChagesBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY_CHANGES);
        applyChagesBtn.onClick = e -> {
            showControlTabs();
            onApplyChanges();
        };  

        var discardChangesBtn:Button = new Button();
        discardChangesBtn.horizontalAlign = 'center';
        discardChangesBtn.width = 150;
        discardChangesBtn.text = Dictionary.getPhrase(ANALYSIS_DISCARD_CHANGES);
        discardChangesBtn.onClick = e -> {
            showControlTabs();
            onDiscardChanges();
        };     

        positionSetupBox = new VBox();
        positionSetupBox.visible = false;
        positionSetupBox.width = PANEL_WIDTH;
        positionSetupBox.height = PANEL_HEIGHT;
        positionSetupBox.addComponent(editModeButtons);
        positionSetupBox.addComponent(turnColorSelectBox);
        positionSetupBox.addComponent(specialEditButtons);
        positionSetupBox.addComponent(fromSIPLabel);
        positionSetupBox.addComponent(SIPInputBox);
        positionSetupBox.addComponent(applyChagesBtn);
        positionSetupBox.addComponent(discardChangesBtn);
    }

    private function createControlTabs() 
    {
        //TODO: Simplified sidebox, (<- ?) flip board btn, analyze btns, export btns, edit position btn
        var sidebox:Sidebox;

        var overviewTab:Box = new Box();
        overviewTab.text = "Overview"; //! Replace

        variantTree = new VariantTree(onBranchSelected);

        var treeWrapper:SpriteWrapper = new SpriteWrapper();
        treeWrapper.sprite = variantTree;

        var treeContainer:ScrollView = new ScrollView();
        treeContainer.width = PANEL_WIDTH;
        treeContainer.height = PANEL_HEIGHT;
        treeContainer.addComponent(treeWrapper);

        var branchingTab:Box = new Box();
        branchingTab.text = "Branches"; //! Replace
        branchingTab.addComponent(treeContainer);

        var openingTeaserLabel:Label = new Label();
        openingTeaserLabel.horizontalAlign = 'center';
        openingTeaserLabel.verticalAlign = 'center';
        openingTeaserLabel.text = "Coming soon"; //! Replace

        var openingTab:Box = new Box();
        openingTab.text = "Opening"; //! Replace
        openingTab.addComponent(openingTeaserLabel);

        controlTabs = new TabView();
        controlTabs.width = PANEL_WIDTH;
        controlTabs.height = PANEL_HEIGHT;
    }

    private function constructButton(mode:PosEditMode):Button 
    {
        var btn:Button = new Button();
        btn.icon = haxe.ui.util.Variant.fromImageData(AssetManager.getAnalysisPosEditorBtnIcon(mode));
        btn.width = 50;
        btn.height = 50;
        btn.toggle = true;
        btn.onClick = e -> {
            pressedEditModeBtn.selected = false;
            pressedEditModeBtn = btn;
            onModeChanged(mode);
        };

        if (mode == Move)
        {
            btn.selected = true;
            pressedEditModeBtn = btn;
        }

        return btn;
    }
}