package gfx.components.gamefield.analysis;

import struct.Ply;
import utils.AssetManager;
import gfx.components.gamefield.common.MoveNavigator;
import gfx.components.gamefield.modules.gameboards.AnalysisField;
import js.Browser;
import dict.Phrase;
import haxe.Timer;
import struct.Situation;
import analysis.AlphaBeta;
import haxe.ui.styles.Style;
import gfx.utils.PlyScrollType;
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
import gfx.components.gamefield.analysis.PosEditMode;
using utils.CallbackTools;

class RightPanel extends Sprite
{
    private static var PANEL_WIDTH = 400;
    private static var PANEL_HEIGHT = 500;

    private var positionSetupBox:VBox;
    private var controlTabs:TabView;
    private var pressedEditModeBtn:Button;

    private static var defaultScoreStyle:Style = {fontSize: 24};
    private var scoreLabel:Label;
    public var navigator(default, null):MoveNavigator;
    public var variantTree(default, null):VariantTree;

    public var onClearPressed:Void->Void;
    public var onResetPressed:Void->Void;
    public var onAnalyzePressed:PieceColor->Void;
    public var onConstructFromSIPPressed:String->Void;
    public var onExportSIPRequested:Void->Void;
    public var onBranchClick:Array<Int>->Void;
    public var onBranchCtrlClick:Array<Int>->Void;
    public var onTurnColorChanged:PieceColor->Void;
    public var onApplyChangesPressed:Void->Void;
    public var onDiscardChangesPressed:Void->Void;
    public var onEditModeChanged:PosEditMode->Void;
    public var scrollingCallback:PlyScrollType->Void;

    public function displayAnalysisResults(result:EvaluationResult) 
    {
        scoreLabel.text = result.score.toString();
    }

    public function displayLoadingOnScoreLabel()
    {
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "...";
    }

    public function showPositionEditor() 
    {
        controlTabs.visible = false;
        positionSetupBox.visible = true;
    }

    public function showControlTabs() 
    {
        positionSetupBox.visible = false;
        controlTabs.visible = true;
    }

    /*public function initVariant(variant:Variant)
    {
        variantTree.init(variant);
    }*/

    public function clearAnalysisScore() 
    {
        scoreLabel.text = "";
    }

    public function deprecateScore() 
    {
        scoreLabel.customStyle = {fontSize: 24, color: 0xCCCCCC};
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
            editModeButtons.addComponent(constructEditorButton(mode));

        var clearButton:Button = new Button();
        clearButton.horizontalAlign = 'center';
        clearButton.width = 100;
        clearButton.text = Dictionary.getPhrase(ANALYSIS_CLEAR);
        clearButton.onClick = e -> {onClearPressed();};

        var resetButton:Button = new Button();
        resetButton.horizontalAlign = 'center';
        resetButton.width = 100;
        resetButton.text = Dictionary.getPhrase(ANALYSIS_RESET);
        resetButton.onClick = e -> {onResetPressed();};

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
        clearButton.onClick = e -> {onConstructFromSIPPressed(fromSIPInput.text);};

        var SIPInputBox:HBox = new HBox();
        clearButton.horizontalAlign = 'left';
        SIPInputBox.addComponent(fromSIPInput);
        SIPInputBox.addComponent(fromSIPApplyBtn);

        var applyChagesBtn:Button = new Button();
        applyChagesBtn.horizontalAlign = 'center';
        applyChagesBtn.width = 150;
        applyChagesBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY_CHANGES);
        applyChagesBtn.onClick = e -> {onApplyChangesPressed();};  

        var discardChangesBtn:Button = new Button();
        discardChangesBtn.horizontalAlign = 'center';
        discardChangesBtn.width = 150;
        discardChangesBtn.text = Dictionary.getPhrase(ANALYSIS_DISCARD_CHANGES);
        discardChangesBtn.onClick = e -> {onDiscardChangesPressed();}; 

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
        //TODO: flip board btn, export as study & as puzzle btns
        navigator = new MoveNavigator(m -> {scrollingCallback(m);});
        navigator.horizontalAlign = 'center';

        var exportSIPBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_SIP, 300, () -> {onExportSIPRequested();});
        exportSIPBtn.horizontalAlign = 'center';

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(createSimpleBtn(ANALYSIS_ANALYZE_WHITE, 150, () -> {onAnalyzePressed(White);}));
        analysisBtns.addComponent(createSimpleBtn(ANALYSIS_ANALYZE_BLACK, 150, () -> {onAnalyzePressed(Black);}));
        analysisBtns.horizontalAlign = 'center';

        scoreLabel = new Label();
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.width = 200;
        scoreLabel.textAlign = "center";
        scoreLabel.horizontalAlign = 'center';

        var setPositionBtn:Button = createSimpleBtn(ANALYSIS_SET_POSITION, 300, showPositionEditor);
        setPositionBtn.horizontalAlign = 'center';

        var overviewVBox:VBox = new VBox();
        overviewVBox.addComponent(navigator);
        overviewVBox.addComponent(exportSIPBtn);
        overviewVBox.addComponent(analysisBtns);
        overviewVBox.addComponent(scoreLabel);
        overviewVBox.addComponent(setPositionBtn);

        var overviewTab:Box = new Box();
        overviewTab.text = Dictionary.getPhrase(ANALYSIS_OVERVIEW_TAB_NAME);
        overviewTab.addComponent(overviewVBox);

        variantTree = new VariantTree(c -> {onBranchClick(c);}, c -> {onBranchCtrlClick(c);});

        var treeWrapper:SpriteWrapper = new SpriteWrapper();
        treeWrapper.sprite = variantTree;

        var treeContainer:ScrollView = new ScrollView();
        treeContainer.width = PANEL_WIDTH;
        treeContainer.height = PANEL_HEIGHT;
        treeContainer.addComponent(treeWrapper);

        var branchingTab:Box = new Box();
        branchingTab.text = Dictionary.getPhrase(ANALYSIS_BRANCHES_TAB_NAME);
        branchingTab.addComponent(treeContainer);

        var openingTeaserLabel:Label = new Label();
        openingTeaserLabel.horizontalAlign = 'center';
        openingTeaserLabel.verticalAlign = 'center';
        openingTeaserLabel.text = Dictionary.getPhrase(ANALYSIS_OPENINGS_TEASER_TEXT);

        var openingTab:Box = new Box();
        openingTab.text = Dictionary.getPhrase(ANALYSIS_OPENINGS_TAB_NAME);
        openingTab.addComponent(openingTeaserLabel);

        controlTabs = new TabView();
        controlTabs.width = PANEL_WIDTH;
        controlTabs.height = PANEL_HEIGHT;
    }

    private function constructEditorButton(mode:PosEditMode):Button 
    {
        var btn:Button = new Button();
        btn.icon = haxe.ui.util.Variant.fromImageData(AssetManager.getAnalysisPosEditorBtnIcon(mode));
        btn.width = 50;
        btn.height = 50;
        btn.toggle = true;
        btn.onClick = e -> {
            pressedEditModeBtn.selected = false;
            pressedEditModeBtn = btn;
            onEditModeChanged(mode);
        };

        if (mode == Move)
        {
            btn.selected = true;
            pressedEditModeBtn = btn;
        }

        return btn;
    }

    private function createSimpleBtn(phrase:Phrase, width:Float, callback:Void->Void):Button
    {
        var btn = new Button();
        btn.width = width;
        btn.text = Dictionary.getPhrase(phrase);
        btn.onClick = callback.expand();
        return btn;
    }
}