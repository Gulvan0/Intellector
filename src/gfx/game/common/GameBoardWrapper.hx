package gfx.game.common;

import haxe.ui.core.Component;
import gfx.game.board.GameBoard;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Box;

class GameBoardWrapper extends Box implements IGameComponent
{
    private var gameboard:GameBoard;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen)
    {
        gameboard = new GameBoard(model, gameScreen);
        gameboard.percentWidth = 100;
        gameboard.percentHeight = 100;
        addComponent(gameboard);

        GlobalBroadcaster.addObserver(gameboard);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        gameboard.handleModelUpdate(model, event);
    }
    
    public function destroy()
    {
        GlobalBroadcaster.removeObserver(gameboard);
    }

    public function asComponent():Component
    {
        return this;
    }

    public function new()
    {
        super();
        this.percentWidth = 100;
        this.percentHeight = 100;
    }
}