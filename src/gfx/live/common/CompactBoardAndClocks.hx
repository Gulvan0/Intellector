package gfx.live.common;

import gfx.live.interfaces.IGameComponent;
import GlobalBroadcaster.GlobalEvent;
import gfx.live.board.GameBoard;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import net.shared.PieceColor;
import haxe.Timer;
import gfx.live.models.ReadOnlyModel;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.events.GameboardEvent;
import gfx.live.interfaces.IGameComponentObserver;

using gfx.live.models.CommonModelExtractors;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/compact_board_and_clocks.xml"))
class CompactBoardAndClocks extends VBox implements IGameComponent
{
    private var orientation:PieceColor = White;

    public var board:GameBoardWrapper;

    public function new() 
    {
        super();
        this.board = new GameBoardWrapper();
        board.percentWidth = 100;
        board.percentHeight = 100;
        content.addComponent(board);

        whiteClock.resize(30);
        blackClock.resize(30);
    }

    public function init(model:ReadOnlyModel, gameScreen:IGameComponentObserver)
    {
        GlobalBroadcaster.addObserver(this);
    }
    
    public function destroy()
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event
        {
            case OrientationUpdated:
                setOrientation(model.getOrientation());
            default:
        }
    }

    private function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case PreferenceUpdated(Marking):
                Timer.delay(doLayout, 40);
            default:
        }
    }

    @:bind(container, UIEvent.RESIZE)
    private function onContainerResize(_) 
    {
        doLayout();
    }

    private function setOrientation(newOrientation:PieceColor)
    {
        if (orientation == newOrientation)
            return;

        switch orientation 
        {
            case White:
                headerContainer.removeComponent(blackDetailsBox, false);
                footerContatiner.removeComponent(whiteDetailsBox, false);
                headerContainer.addComponent(whiteDetailsBox);
                footerContatiner.addComponent(blackDetailsBox);
            case Black:
                headerContainer.removeComponent(whiteDetailsBox, false);
                footerContatiner.removeComponent(blackDetailsBox, false);
                headerContainer.addComponent(blackDetailsBox);
                footerContatiner.addComponent(whiteDetailsBox);
        }

        orientation = newOrientation;
    }

    private function doLayout() 
    {
        var aspectRatio:Float = board.inverseAspectRatio();

        var containerWidth:Float = container.width - 2; // account for padding
        var containerHeight:Float = container.height - 2 - 60; // account for padding, header, footer

        var proposedWidth:Float = containerWidth;
        var proposedHeight:Float = proposedWidth * aspectRatio;

        contentContainer.width = containerWidth;

        if (proposedHeight <= containerHeight) 
        {
            content.width = proposedWidth;
            content.height = proposedHeight;
        }
        else 
        {
            content.width = containerHeight / aspectRatio;
            content.height = containerHeight;
        }
    }
}