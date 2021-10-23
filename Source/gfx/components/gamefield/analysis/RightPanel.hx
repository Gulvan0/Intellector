package gfx.components.gamefield.analysis;

import openfl.text.TextFormat;
import openfl.events.Event;
import haxe.ui.components.Image;
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
import haxe.ui.util.Variant as UIVariant;
using utils.CallbackTools;

class RightPanel extends Sprite
{
    private static var PANEL_WIDTH = 400;
    private static var PANEL_HEIGHT = 500;

    private var positionSetupBox:VBox;
    private var controlTabs:TabView;
    private var pressedEditModeBtn:Button;
    private var defaultEditModeBtn:Button;

    private static var defaultScoreStyle:Style = {fontSize: 24};
    private var scoreLabel:Label;
    private var turnColorSelectOptions:Map<PieceColor, OptionBox>;
    public var navigator(default, null):MoveNavigator;
    public var variantTree(default, null):VariantTree;
    
    private var variantTreeSprite:Sprite;
    private var variantTreeBG:Sprite;
    private var variantTreeVBox:VBox;
    private var overviewTab:Box;

    public var onClearPressed:Void->Void;
    public var onResetPressed:Void->Void;
    public var onAnalyzePressed:PieceColor->Void;
    public var onConstructFromSIPPressed:String->Void;
    public var onExportSIPRequested:Void->Void;
    public var onExportStudyRequested:Void->Void;
    public var onBranchClick:Array<Int>->Void;
    public var onBranchCtrlClick:Array<Int>->Void;
    public var onTurnColorChanged:PieceColor->Void;
    public var onApplyChangesPressed:Void->Void;
    public var onDiscardChangesPressed:Void->Void;
    public var onEditModeChanged:PosEditMode->Void;
    public var scrollingCallback:PlyScrollType->Void;
    public var readyCallback:Void->Void;

    public function displayAnalysisResults(result:EvaluationResult) 
    {
        scoreLabel.text = result.score.toString();
    }

    public function displayLoadingOnScoreLabel()
    {
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "...";
    }

    public function updateBranchingTabContentSize() 
    {
        variantTreeBG.width = variantTreeVBox.width = Math.max(390, 145 + variantTreeSprite.width);
		variantTreeBG.height = variantTreeVBox.height = Math.max(360, 20 + variantTreeSprite.height);
    }

    public function changeEditorColorOptions(selectedColor:PieceColor) 
    {
        turnColorSelectOptions[selectedColor].selected = true;
        turnColorSelectOptions[opposite(selectedColor)].selected = false;
    }

    public function showPositionEditor() 
    {
        pressedEditModeBtn.selected = false;
        defaultEditModeBtn.selected = true;
        pressedEditModeBtn = defaultEditModeBtn;

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
        scoreLabel.text = "-";
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

        var turnColorSelectBox:HBox = new HBox();
        turnColorSelectBox.horizontalAlign = 'center';

        turnColorSelectOptions = [];

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
            turnColorSelectOptions.set(color, optionBox);
            turnColorSelectBox.addComponent(optionBox);
        }    

        var clearButton:Button = new Button();
        clearButton.width = 150;
        clearButton.text = Dictionary.getPhrase(ANALYSIS_CLEAR);
        clearButton.onClick = e -> {onClearPressed();};

        var resetButton:Button = new Button();
        resetButton.width = 150;
        resetButton.text = Dictionary.getPhrase(ANALYSIS_RESET);
        resetButton.onClick = e -> {onResetPressed();};

        var specialEditButtons:HBox = new HBox();
        specialEditButtons.horizontalAlign = 'center';
        specialEditButtons.addComponent(clearButton);
        specialEditButtons.addComponent(Shapes.hSpacer(30));
        specialEditButtons.addComponent(resetButton);

        var fromSIPLabel:Label = new Label();
        fromSIPLabel.horizontalAlign = 'left';
        fromSIPLabel.text = Dictionary.getPhrase(FROM_SIP_LABEL);
        fromSIPLabel.customStyle = {fontSize: 20, fontItalic: true};

        var fromSIPInput:TextField = new TextField();
        fromSIPInput.width = 310;

        var fromSIPApplyBtn:Button = new Button();
        fromSIPApplyBtn.width = 80;
        fromSIPApplyBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY);
        fromSIPApplyBtn.onClick = e -> {
            var sip = fromSIPInput.text;
            fromSIPInput.text = "";
            onConstructFromSIPPressed(sip);
        };

        var SIPInputBox:HBox = new HBox();
        clearButton.horizontalAlign = 'left';
        SIPInputBox.addComponent(fromSIPInput);
        SIPInputBox.addComponent(fromSIPApplyBtn);

        var applyChagesBtn:Button = new Button();
        applyChagesBtn.horizontalAlign = 'center';
        applyChagesBtn.width = 300;
        applyChagesBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY_CHANGES);
        applyChagesBtn.onClick = e -> {onApplyChangesPressed();};  

        var discardChangesBtn:Button = new Button();
        discardChangesBtn.horizontalAlign = 'center';
        discardChangesBtn.width = 300;
        discardChangesBtn.text = Dictionary.getPhrase(ANALYSIS_DISCARD_CHANGES);
        discardChangesBtn.onClick = e -> {onDiscardChangesPressed();}; 

        positionSetupBox = new VBox();
        positionSetupBox.visible = false;
        positionSetupBox.width = PANEL_WIDTH;
        positionSetupBox.height = PANEL_HEIGHT;
        positionSetupBox.addComponent(editModeButtons);
        positionSetupBox.addComponent(Shapes.vSpacer(10));
        positionSetupBox.addComponent(specialEditButtons);
        positionSetupBox.addComponent(Shapes.vSpacer(10));
        positionSetupBox.addComponent(turnColorSelectBox);
        positionSetupBox.addComponent(Shapes.vSpacer(40));
        positionSetupBox.addComponent(fromSIPLabel);
        positionSetupBox.addComponent(SIPInputBox);
        positionSetupBox.addComponent(Shapes.vSpacer(40));
        positionSetupBox.addComponent(applyChagesBtn);
        positionSetupBox.addComponent(discardChangesBtn);
    }

    private function createControlTabs() 
    {
        //TODO: flip board btn, export as puzzle btn
        navigator = new MoveNavigator(m -> {scrollingCallback(m);});
        navigator.horizontalAlign = 'center';

        var setPositionBtn:Button = createSimpleBtn(ANALYSIS_SET_POSITION, 300, () -> {
            onEditModeChanged(Move);
            showPositionEditor();
        });
        setPositionBtn.horizontalAlign = 'center';

        var exportSIPBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_SIP, 300, () -> {onExportSIPRequested();});
        exportSIPBtn.horizontalAlign = 'center';

        var exportStudyBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_STUDY, 300, () -> {onExportStudyRequested();});
        exportStudyBtn.horizontalAlign = 'center';

        var analyzeWhiteBtn = createSimpleBtn(ANALYSIS_ANALYZE_WHITE, 150, () -> {onAnalyzePressed(White);});
        analyzeWhiteBtn.disabled = true;
        var analyzeBlackBtn = createSimpleBtn(ANALYSIS_ANALYZE_BLACK, 150, () -> {onAnalyzePressed(Black);});
        analyzeBlackBtn.disabled = true;

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(analyzeWhiteBtn);
        analysisBtns.addComponent(analyzeBlackBtn);
        analysisBtns.horizontalAlign = 'center';

        scoreLabel = new Label();
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "-";
        scoreLabel.width = 200;
        scoreLabel.textAlign = "center";
        scoreLabel.horizontalAlign = 'center';

        var overviewVBox:VBox = new VBox();
        overviewVBox.horizontalAlign = 'center';
        overviewVBox.verticalAlign = 'center';
        overviewVBox.addComponent(navigator);
        overviewVBox.addComponent(setPositionBtn);
        overviewVBox.addComponent(exportSIPBtn);
        overviewVBox.addComponent(exportStudyBtn);
        overviewVBox.addComponent(analysisBtns);
        overviewVBox.addComponent(scoreLabel);

        overviewTab = new Box();
        overviewTab.text = Dictionary.getPhrase(ANALYSIS_OVERVIEW_TAB_NAME);
        overviewTab.width = PANEL_WIDTH - 10;
        overviewTab.height = 360;
        overviewTab.addComponent(overviewVBox);

        variantTree = new VariantTree(c -> {onBranchClick(c);}, c -> {onBranchCtrlClick(c);});
		variantTree.x = 20; 
        variantTree.y = 20; 
        
        variantTreeBG = Shapes.fillOnlyRect(390, 360, 0xffffff);

        variantTreeSprite = new Sprite();
        variantTreeSprite.addChild(variantTree);

        var treeWrapper:SpriteWrapper = new SpriteWrapper();
        treeWrapper.sprite = variantTreeSprite;
		
		variantTreeVBox = new VBox();
		variantTreeVBox.width = 390;
		variantTreeVBox.height = 360;
		variantTreeVBox.addComponent(treeWrapper);

        var treeContainer:ScrollView = new ScrollView();
        treeContainer.horizontalAlign = 'center';
        treeContainer.verticalAlign = 'center';
        treeContainer.width = PANEL_WIDTH - 10;
        treeContainer.height = 463;
        treeContainer.addComponent(variantTreeVBox);

        var branchingTab:Box = new Box();
        branchingTab.width = PANEL_WIDTH - 10;
        branchingTab.height = 463;
        branchingTab.text = Dictionary.getPhrase(ANALYSIS_BRANCHES_TAB_NAME);
        branchingTab.addComponent(treeContainer);

        var openingTeaserLabel:Label = new Label();
        openingTeaserLabel.customStyle = {fontSize: 20};
        openingTeaserLabel.horizontalAlign = 'center';
        openingTeaserLabel.verticalAlign = 'center';
        openingTeaserLabel.text = Dictionary.getPhrase(ANALYSIS_OPENINGS_TEASER_TEXT);

        var openingTab:Box = new Box();
        openingTab.text = Dictionary.getPhrase(ANALYSIS_OPENINGS_TAB_NAME);
        openingTab.width = PANEL_WIDTH - 10;
        openingTab.height = 360;
        openingTab.addComponent(openingTeaserLabel);

        controlTabs = new TabView();
        controlTabs.width = PANEL_WIDTH;
        controlTabs.height = PANEL_HEIGHT;
        controlTabs.addComponent(overviewTab);
        controlTabs.addComponent(branchingTab);
        controlTabs.addComponent(openingTab);

        controlTabs.addEventListener(Event.ADDED_TO_STAGE, onControlTabsAdded);
        /*var v:Variant = new Variant();
		new Timer(5000).run = () -> {
            var a = v.extendPathLeftmost([]);
			variantTree.addChildNode(a, "Lol", false,v);
			v.addChildToNode(new Ply(), a);
			variantTreeVBox.width = Math.max(390, 145 + variantTreeSprite.width);
			variantTreeVBox.height = Math.max(360, 20 + variantTreeSprite.height);
		}*/
    }

    private function onControlTabsAdded(e) 
    {
        controlTabs.removeEventListener(Event.ADDED_TO_STAGE, onControlTabsAdded);
        //controlTabs.addComponentAt(overviewTab, 0);
        controlTabs.pageIndex = 1;

        var tf:openfl.text.TextField = new openfl.text.TextField();
        tf.text = Dictionary.getPhrase(BRANCH_REMOVE_HINT);
        tf.selectable = false;
        tf.setTextFormat(new TextFormat(null, 16, null, null, true));
        tf.y = -5;
        tf.width = 300;

        Timer.delay(() -> {
            variantTreeSprite.addChildAt(variantTreeBG, 0);
            variantTreeSprite.addChildAt(tf, 1);
            controlTabs.pageIndex = 0;
            readyCallback();
        }, 20);
    }

    private function constructEditorButton(mode:PosEditMode):Button 
    {
        var btn:Button = new Button();
        var bmpData = AssetManager.getAnalysisPosEditorBtnIcon(mode);
        var scaleMultiplier = 45 / Math.max(bmpData.width, bmpData.height);
        switch mode 
        {
            case Set(type, color):
                if (type == Progressor)
                    scaleMultiplier *= 0.7;
                else if (type == Liberator || type == Defensor)
                    scaleMultiplier *= 0.9;
            default:
        }
        btn.icon = bmpData;
        btn.width = 50;
        btn.height = 50;

        function resizeIcon(e:Event) 
        {
            btn.removeEventListener(Event.ADDED_TO_STAGE, resizeIcon);
            var imgComponent = btn.findComponent(Image);
            imgComponent.width *= scaleMultiplier;
            imgComponent.height *= scaleMultiplier;
        }

        if (mode != Move && mode != Delete)
            btn.addEventListener(Event.ADDED_TO_STAGE, resizeIcon);
        
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
            defaultEditModeBtn = btn;
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