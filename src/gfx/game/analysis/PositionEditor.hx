package gfx.game.analysis;

import gfx.game.board.subcomponents.Piece;
import gfx.game.analysis.util.PosEditMode;
import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import gfx.game.events.PositionEditorEvent;
import haxe.ui.core.Component;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import net.shared.board.Situation;
import haxe.ui.components.Image;
import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;
import gfx.Dialogs;
import net.shared.PieceColor;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/position_editor.xml"))
class PositionEditor extends VBox implements IGameComponent
{
    private var eventHandler:PositionEditorEvent->Void;

    private var editModeBtns:Map<PosEditMode, Button>;
    private var toolBtns:Array<Button>;

    public function init(model:ReadOnlyModel, getBehaviour:Void->IBehaviour):Void
    {
        this.eventHandler = getBehaviour().handlePositionEditorEvent;

        editModeBtns = [
            Move => moveModeBtn,
            Set(Progressor, White) => setProgWhiteModeBtn,
            Set(Aggressor, White) => setAgrWhiteModeBtn,
            Set(Defensor, White) => setDefWhiteModeBtn,
            Set(Liberator, White) => setLibWhiteModeBtn,
            Set(Dominator, White) => setDomWhiteModeBtn,
            Set(Intellector, White) => setIntWhiteModeBtn,
            Delete => deleteModeBtn,
            Set(Progressor, Black) => setProgBlackModeBtn,
            Set(Aggressor, Black) => setAgrBlackModeBtn,
            Set(Defensor, Black) => setDefBlackModeBtn,
            Set(Liberator, Black) => setLibBlackModeBtn,
            Set(Dominator, Black) => setDomBlackModeBtn,
            Set(Intellector, Black) => setIntBlackModeBtn
        ];

        toolBtns = [orientationBtn, importBtn, clearBtn, resetBtn, startBtn];


        for (mode => btn in editModeBtns)
            btn.onClick = e -> {eventHandler(EditModeChangeRequested(mode));};
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        var analysisModel:IReadOnlyAnalysisBoardModel;

        switch model 
        {
            case AnalysisBoard(model):
                analysisModel = model;
            default:
                throw "PositionEditor is only available for AnalysisBoardModel";
        }

        switch event 
        {
            case EditorSituationUpdated:
                turnColorStepper.selectedIndex = analysisModel.getEditorSituation().turnColor == White? 0 : 1;
            case EditorModeUpdated:
                editModeBtns.get(analysisModel.getEditorMode()).selected = true;
            default:
        }
    }

    public function destroy():Void
    {
        //* Do nothing
    }

    public function asComponent():Component
    {
        return this;
    }

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        var spacing:Float = 5;
        var padding:Float = 10;
        var maxBtnWidth:Float = (width - spacing * (7 - 1)) / 7;
        var maxBtnHeight:Float = (height - spacing * (4 - 1) - padding * 2) / 4;

        var btnSide:Float = Math.min(maxBtnWidth, maxBtnHeight);

        for (mode => btn in editModeBtns)
        {
            var icon:Image = btn.findComponent(Image);
            var iconMaxSide:Float = 0.7 * btnSide;

            btn.width = btnSide;
            btn.height = btnSide;

            switch mode 
            {
                case Move, Delete:
                    icon.width = iconMaxSide;
                    icon.height = iconMaxSide;
                case Set(type, color):
                    icon.height = Piece.pieceRelativeScale(type) * iconMaxSide;
                    icon.width = Piece.pieceRelativeScale(type) * iconMaxSide;
            }
        }

        var additionalRowHeight:Float = btnSide * 0.8;

        for (btn in toolBtns)
        {
            var icon:Image = btn.findComponent(Image);

            btn.width = additionalRowHeight;
            btn.height = additionalRowHeight;
            icon.width = additionalRowHeight;
            icon.height = additionalRowHeight;
        }

        otherOptionsHBox.width = btnSide * 7 + spacing * (7 - 1);
        turnColorStepper.customStyle = {fontSize: additionalRowHeight / 3, textAlign: 'center'};
        applyChangesBtn.customStyle = {fontSize: additionalRowHeight / 2};
        discardChangesBtn.customStyle = {fontSize: additionalRowHeight / 2};

        return true;
    }

    @:bind(importBtn, MouseEvent.CLICK)
    private function onImportSIPPressed(e)
    {
        var deserializedSituation:Null<Situation> = null;
        var response:Null<String> = Browser.window.prompt(Dictionary.getPhrase(ANALYSIS_INPUT_SIP_PROMPT_TEXT));
        
        if (response != null)
            deserializedSituation = Situation.deserialize(response);
        
        if (deserializedSituation != null)
            eventHandler(SituationImported(deserializedSituation));
        else
            Dialogs.alert(ANALYSIS_INVALID_SIP_WARNING_TEXT, ANALYSIS_INVALID_SIP_WARNING_TITLE);
    }

    @:bind(turnColorStepper, UIEvent.CHANGE)
    private function onTurnColorChanged(e)
    {
        var turnColor:PieceColor = turnColorStepper.selectedIndex == 0? White : Black;
        eventHandler(TurnColorChangeRequested(turnColor));
    }

    @:bind(applyChangesBtn, MouseEvent.CLICK)
    private function onApplyChangesPressed(e)
    {
        eventHandler(ApplyChangesRequested);
    }

    @:bind(discardChangesBtn, MouseEvent.CLICK)
    private function onDiscardChangesPressed(e)
    {
        eventHandler(DiscardChangesRequested);
    }

    @:bind(clearBtn, MouseEvent.CLICK)
    private function onClearPressed(e)
    {
        eventHandler(ClearRequested);
    }

    @:bind(resetBtn, MouseEvent.CLICK)
    private function onResetPressed(e)
    {
        eventHandler(ResetRequested);
    }

    @:bind(startBtn, MouseEvent.CLICK)
    private function onStartPosPressed(e)
    {
        eventHandler(StartPosRequested);
    }

    @:bind(orientationBtn, MouseEvent.CLICK)
    private function onChangeOrientationPressed(e)
    {
        eventHandler(OrientationChangeRequested);
    }

    public function new()
    {
        super();
    }
}