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

    private var variant:Variant; 
    private var variantTree:VariantTree;

    private static var defaultScoreStyle:Style = {fontSize: 24};
    private var field:AnalysisField;
    private var scoreLabel:Label;
    private var navigator:MoveNavigator;

    private function onAnalyzePressed(color:PieceColor) 
    {
        scoreLabel.customStyle = defaultScoreStyle;
        scoreLabel.text = "...";

        Timer.delay(() -> {
            var situation:Situation = field.currentSituation.copy();
            situation.setTurnWithZobris(color);
            AlphaBeta.initMeasuredIndicators();
            var result = AlphaBeta.findMate(situation, 10, situation.turnColor == White);//AlphaBeta.evaluate(situation, 6);
            #if measure_time
            trace("Prune count: " + AlphaBeta.prunedCount + "; Prune ratio: " + AlphaBeta.prunedCount / (AlphaBeta.prunedCount + AlphaBeta.evaluatedCount));
            for (act in MeasuredProcess.createAll())
            {
                trace(act.getName());
                trace("Calls: " + AlphaBeta.calls[act] + "; Avg: " + (AlphaBeta.totalTime[act] / AlphaBeta.calls[act]) + "; Total: " + AlphaBeta.totalTime[act]);
            }
            #end
            var recommendedMove = result.optimalPly;
                
            scoreLabel.text = result.score.toString();
            field.rmbSelectionBackToNormal();
            field.drawArrow(recommendedMove.from, recommendedMove.to);
        }, 20);
    }

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
        this.variant = variant;
        variantTree.init(variant);
    }

    private function onClear() 
    {
        scoreLabel.text = "";
        field.clearBoard();
    }

    private function onReset() 
    {
        scoreLabel.text = "";
        field.reset();
    }

    private function onExportSIP() 
    {
        Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_EXPORTED_SIP_MESSAGE), field.currentSituation.serialize());
    }

    private function deprecateScore() 
    {
        scoreLabel.customStyle = {fontSize: 24, color: 0xCCCCCC};
    }

    private function onBranchSelected(code:String) 
    {
        //TODO: Deselect former selected, store selected, highlight arrows, redraw field's figures, reinit navigator
    }

    private function onBranchRemoved(code:String)
    {
        //TODO: If belongs to a selected branch, select a new branch and redraw figures on a field, reinit navigator
        variant.removeByCode(code);
        variantTree.init(variant); //TODO: Remove and then add again TreeWrapper on TreeContainer. These components need to be stored in the properties
    }

    public function makeMove(ply:Ply) 
    {
        navigator.writePly(ply, field.currentSituation);
        //TODO: Change variant & variantTree    
        deprecateScore();
    }

    public function new(field:AnalysisField) 
    {
        super();
        this.field = field;

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
        clearButton.onClick = onClear.expand();

        var resetButton:Button = new Button();
        resetButton.horizontalAlign = 'center';
        resetButton.width = 100;
        resetButton.text = Dictionary.getPhrase(ANALYSIS_RESET);
        resetButton.onClick = onReset.expand();

        var turnColorSelectBox:HBox = new HBox();
        turnColorSelectBox.horizontalAlign = 'center';

        for (color in PieceColor.createAll())
        {
            var optionBox:OptionBox = new OptionBox();
            optionBox.text = Dictionary.getAnalysisTurnColorSelectLabel(color);
            optionBox.componentGroup = "analysis-editor-turncolor";
            optionBox.onChange = (e) -> {
                if (optionBox.selected)
                    field.currentSituation.setTurnWithZobris(color);
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
        clearButton.onClick = e -> {field.constructFromSIP(fromSIPInput.text);};

        var SIPInputBox:HBox = new HBox();
        clearButton.horizontalAlign = 'left';
        SIPInputBox.addComponent(fromSIPInput);
        SIPInputBox.addComponent(fromSIPApplyBtn);

        var applyChagesBtn:Button = new Button();
        applyChagesBtn.horizontalAlign = 'center';
        applyChagesBtn.width = 150;
        applyChagesBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY_CHANGES);
        applyChagesBtn.onClick = e -> {
            deprecateScore();
            showControlTabs();
            field.applyChanges();
        };  

        var discardChangesBtn:Button = new Button();
        discardChangesBtn.horizontalAlign = 'center';
        discardChangesBtn.width = 150;
        discardChangesBtn.text = Dictionary.getPhrase(ANALYSIS_DISCARD_CHANGES);
        discardChangesBtn.onClick = e -> {
            showControlTabs();
            field.discardChanges();
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
        //TODO: flip board btn, export as study & as puzzle btns
        navigator = new MoveNavigator(field.applyScrolling);
        navigator.horizontalAlign = 'center';

        var exportSIPBtn:Button = createSimpleBtn(ANALYSIS_EXPORT_SIP, 300, onExportSIP);
        exportSIPBtn.horizontalAlign = 'center';

        var analysisBtns:HBox = new HBox();
        analysisBtns.addComponent(createSimpleBtn(ANALYSIS_ANALYZE_WHITE, 150, onAnalyzePressed.bind(White)));
        analysisBtns.addComponent(createSimpleBtn(ANALYSIS_ANALYZE_BLACK, 150, onAnalyzePressed.bind(Black)));
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

        variantTree = new VariantTree(onBranchSelected, onBranchRemoved);

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
            field.changeEditMode(mode);
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