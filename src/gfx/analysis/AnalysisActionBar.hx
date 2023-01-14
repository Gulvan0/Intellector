package gfx.analysis;

import haxe.ui.components.Button;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.VBox;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/analysis/action_bar.xml"))
class AnalysisActionBar extends VBox implements IAnalysisPeripheralEventObserver
{
    private var eventHandler:PeripheralEvent->Void;

    public function handleAnalysisPeripheralEvent(event:PeripheralEvent)
    {
        switch event 
        {
            case ApplyChangesRequested:
                hidden = false;
            case DiscardChangesRequested:
                hidden = false;
            case EditorLaunchRequested:
                hidden = true;
            default:
        }
    }

    @:bind(changeOrientationBtn, MouseEvent.CLICK)
    private function onChangeOrientationPressed(e)
    {
        eventHandler(OrientationChangeRequested);
    }

    @:bind(editPositionBtn, MouseEvent.CLICK)
    private function onEditPositionPressed(e)
    {
        eventHandler(EditorLaunchRequested);
    }
    
    @:bind(shareBtn, MouseEvent.CLICK)
    private function onSharePressed(e)
    {
        eventHandler(ShareRequested);
    }
    
    @:bind(playFromPosBtn, MouseEvent.CLICK)
    private function onPlayFromPosPressed(e)
    {
        eventHandler(PlayFromHereRequested);
    }
    
    @:bind(prevMoveBtn, MouseEvent.CLICK)
    private function onPrevPressed(e)
    {
        eventHandler(ScrollBtnPressed(Prev));
    }
    
    @:bind(nextMoveBtn, MouseEvent.CLICK)
    private function onNextPressed(e)
    {
        eventHandler(ScrollBtnPressed(Next));
    }

    public function init(compact:Bool, eventHandler:PeripheralEvent->Void)
    {
        this.eventHandler = eventHandler;
        
        var shownButtons:Array<Button> = [changeOrientationBtn, editPositionBtn, shareBtn, playFromPosBtn];

        if (compact)
        {
            shownButtons.push(prevMoveBtn);
            shownButtons.push(nextMoveBtn);
        }

        var btnWidth:Float = 100 / shownButtons.length;
        for (btn in shownButtons)
        {
            btn.hidden = false;
            btn.percentWidth = btnWidth;
        }

        if (!LoginManager.isLogged())
            playFromPosBtn.disabled = true;
    }

    public function new() 
    {
        super();
    }
}