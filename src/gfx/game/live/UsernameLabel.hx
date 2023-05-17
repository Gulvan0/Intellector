package gfx.game.live;

import haxe.ui.styles.Style;
import gfx.game.interfaces.IReadOnlyGameRelatedModel;
import haxe.ui.core.Component;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Box;
import net.shared.PieceColor;
import haxe.ui.events.UIEvent;

using gfx.game.models.CommonModelExtractors;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/username_label.xml"))
class UsernameLabel extends Box implements IGameComponent
{
    private var ownerColor:PieceColor;

    public function init(model:ReadOnlyModel, getBehaviour:Void->IBehaviour)
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        playerRefLabel.text = gameModel.getPlayerRef(ownerColor);

        if (gameModel.hasEnded())
            onlineStatusCircleStack.hidden = true;
        else
            onlineStatusCircleStack.selectedId = gameModel.isPlayerOnline(ownerColor)? "onlineCircle" : "offlineCircle";
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event 
        {
            case GameEnded:
                onlineStatusCircleStack.hidden = true;
            case PlayerOnlineStatusUpdated:
                onlineStatusCircleStack.selectedId = model.asGameModel().isPlayerOnline(ownerColor)? "onlineCircle" : "offlineCircle";
            default:
        }
    }

    public function destroy()
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
        var newCardStyle:Style = card.customStyle.clone();
        newCardStyle.paddingTop = 0.1 * this.height;
        newCardStyle.paddingBottom = 0.1 * this.height;
        newCardStyle.paddingLeft = 0.2 * this.height;
        newCardStyle.paddingRight = 0.2 * this.height;
        card.customStyle = newCardStyle;

        onlineStatusCircleStack.width = 0.32 * this.height;
        onlineStatusCircleStack.height = 0.32 * this.height;

        playerRefLabel.customStyle = {fontSize: 0.48 * this.height};
    }

    public function new(ownerColor:PieceColor) 
    {
        super();
        this.ownerColor = ownerColor;
    }
}