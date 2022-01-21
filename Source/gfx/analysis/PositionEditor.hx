package gfx.analysis;

import haxe.ui.containers.VBox;

enum PositionEditorEvent
{
    ClearPressed;
    ResetPressed;
    ConstructFromSIPPressed(sip:String);
    TurnColorChanged(newTurnColor:PieceColor);
    ApplyChangesPressed;
    DiscardChangesPressed;
    EditModeChanged(newEditMode:PosEditMode);
}

class PositionEditor extends VBox
{
    private var eventHandler:PositionEditorEvent->Void;

    private var pressedEditModeBtn:Button;
    private var defaultEditModeBtn:Button;
    
    private var turnColorSelectOptions:Map<PieceColor, OptionBox>;

    public function init(eventHandler:PositionEditorEvent->Void)
    {
        this.eventHandler = eventHandler;
    }

    public function returnToDefaultEditMode()
    {
        pressedEditModeBtn.selected = false;
        defaultEditModeBtn.selected = true;
        pressedEditModeBtn = defaultEditModeBtn;
    }

    public function changeEditorColorOptions(selectedColor:PieceColor) 
    {
        turnColorSelectOptions[selectedColor].selected = true;
        turnColorSelectOptions[opposite(selectedColor)].selected = false;
    }

    public function new()
    {
        super();

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
                    eventHandler(TurnColorChanged(color));
            };
            if (color == White)
                optionBox.selected = true;
            turnColorSelectOptions.set(color, optionBox);
            turnColorSelectBox.addComponent(optionBox);
        }    

        var clearButton:Button = new Button();
        clearButton.width = 150;
        clearButton.text = Dictionary.getPhrase(ANALYSIS_CLEAR);
        clearButton.onClick = e -> {eventHandler(ClearPressed);};

        var resetButton:Button = new Button();
        resetButton.width = 150;
        resetButton.text = Dictionary.getPhrase(ANALYSIS_RESET);
        resetButton.onClick = e -> {eventHandler(ResetPressed);};

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
            eventHandler(ConstructFromSIPPressed(sip));
        };

        var SIPInputBox:HBox = new HBox();
        clearButton.horizontalAlign = 'left';
        SIPInputBox.addComponent(fromSIPInput);
        SIPInputBox.addComponent(fromSIPApplyBtn);

        var applyChagesBtn:Button = new Button();
        applyChagesBtn.horizontalAlign = 'center';
        applyChagesBtn.width = 300;
        applyChagesBtn.text = Dictionary.getPhrase(ANALYSIS_APPLY_CHANGES);
        applyChagesBtn.onClick = e -> {eventHandler(ApplyChangesPressed);};

        var discardChangesBtn:Button = new Button();
        discardChangesBtn.horizontalAlign = 'center';
        discardChangesBtn.width = 300;
        discardChangesBtn.text = Dictionary.getPhrase(ANALYSIS_DISCARD_CHANGES);
        discardChangesBtn.onClick = e -> {eventHandler(DiscardChangesPressed);};

        this.visible = false;
        this.width = PANEL_WIDTH;
        this.height = PANEL_HEIGHT;
        this.addComponent(editModeButtons);
        this.addComponent(Shapes.vSpacer(10));
        this.addComponent(specialEditButtons);
        this.addComponent(Shapes.vSpacer(10));
        this.addComponent(turnColorSelectBox);
        this.addComponent(Shapes.vSpacer(40));
        this.addComponent(fromSIPLabel);
        this.addComponent(SIPInputBox);
        this.addComponent(Shapes.vSpacer(40));
        this.addComponent(applyChagesBtn);
        this.addComponent(discardChangesBtn);
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
            eventHandler(EditModeChanged(mode));
        };

        if (mode == Move)
        {
            btn.selected = true;
            pressedEditModeBtn = btn;
            defaultEditModeBtn = btn;
        }

        return btn;
    }
}