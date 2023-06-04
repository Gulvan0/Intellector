package gfx.game.common.ply_history_view;

import gfx.game.interfaces.IReadOnlyGenericModel;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IReadOnlyHistory;
import gfx.game.events.PlyHistoryViewEvent;
import gfx.game.interfaces.IGameComponent;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import haxe.ui.events.UIEvent;
import haxe.Timer;
import net.shared.ServerEvent;
import gfx.utils.PlyScrollType;
import haxe.ui.containers.VBox;
import net.shared.PieceColor;

using gfx.game.models.CommonModelExtractors;

abstract class PlyHistoryView extends VBox implements IGameComponent
{
    private var eventHandler:PlyHistoryViewEvent->Void;
    private var genericModel:IReadOnlyGenericModel;

    private abstract function postInit():Void;
    private abstract function appendPlyStr(moveNum:Int, ply:RawPly, situationBefore:Situation):Void;
    private abstract function clear():Void;
    private abstract function onEditorToggled(editorActive:Bool):Void;
    private abstract function onShownMoveUpdated():Void;
    private abstract function refreshElements():Void;
    private abstract function refreshScrollPosition():Void;

    @:bind(this, UIEvent.RESIZE)
    private function onResize(e)
    {
        Timer.delay(refreshScrollPosition, 40);
    }

    private function onScrollRequested(scrollType:PlyScrollType)
    {
        eventHandler(ScrollRequested(scrollType));
    }

    private function onPlySelectedManually(num:Int)
    {
        onScrollRequested(Precise(num));
    }

    private function onPlyAppended()
    {   
        var lastPlyInfo = genericModel.getLastPlyInfo();
        var moveNum:Int = genericModel.getLineLength();

        appendPlyStr(moveNum, lastPlyInfo.ply, lastPlyInfo.situationBefore);
        onShownMoveUpdated();

        refreshElements();
    }

    private function onHistoryRewritten()
    {
        clear();

        var moveNum:Int = 1;
        var situationBefore:Situation = genericModel.getStartingSituation();

        for (plyInfo in genericModel.getLine())
        {
            appendPlyStr(moveNum, plyInfo.ply, situationBefore);
            situationBefore = plyInfo.situationAfter;
            moveNum++;
        }

        onShownMoveUpdated();

        refreshElements();
    }

    public function init(model:ReadOnlyModel, getBehaviour:Void->IBehaviour):Void
    {
        genericModel = model.asGenericModel();
        eventHandler = getBehaviour().handlePlyHistoryViewEvent;

        onHistoryRewritten();

        postInit();
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        switch event 
        {
            case ViewedMoveNumUpdated, SelectedVariationNodeUpdated, VariationUpdated:
                onShownMoveUpdated();
                refreshElements();
            case MoveAddedToHistory:
                onPlyAppended();
            case HistoryRollback, HistoryRewritten:
                onHistoryRewritten();
            case EditorModeUpdated:
                switch model 
                {
                    case AnalysisBoard(model):
                        onEditorToggled(model.isEditorActive());
                    default:
                        throw "EditorModeUpdated can only be emitted by AnalysisBoard";
                }
            default:
        }
    }

    public function destroy():Void
    {
        //* Do nothing
    }
    
    public function new()
    {
        super();
    }  
}