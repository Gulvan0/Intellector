package gfx.game.live;

import gfx.game.interfaces.IBehaviour;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.events.UIEvent;
import net.shared.PieceColor;
import gfx.game.common.ply_history_view.MoveNavigator;
import gfx.game.common.GameComponentLayout;

using gfx.game.models.CommonModelExtractors;

/**
    Short for "Usernames, Clocks, Moves, Actions". A panel to the right of a gameboard, present in any ongoing/past game screen
**/
@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/ucma_box.xml"))
class UCMABox extends GameComponentLayout 
{
    private var usernameLabels:Map<PieceColor, UsernameLabel> = [];
    private var clocks:Map<PieceColor, Clock> = [];
    private var moveNavigator:MoveNavigator;
    private var actionBar:LiveActionBar;

    public function new() 
    {
        super();

        for (color in PieceColor.createAll())
        {
            var usernameLabel:UsernameLabel = new UsernameLabel(color);
            usernameLabel.horizontalAlign = 'center';
            usernameLabels.set(color, usernameLabel);

            var clock:Clock = new Clock(color);
            clock.horizontalAlign = 'center';
            clocks.set(color, clock);
        }

        moveNavigator = new MoveNavigator();
        moveNavigator.percentWidth = 100;
        moveNavigator.percentHeight = 100;

        actionBar = new LiveActionBar(false);
        actionBar.percentWidth = 100;

        center.addComponent(moveNavigator);
        center.addComponent(actionBar);

        setOrientation(model.asGenericModel().getOrientation());
    }

    private function getChildGameComponents():Array<IGameComponent>
    {
        var a:Array<IGameComponent> = [moveNavigator, actionBar];

        for (label in usernameLabels)
            a.push(label);

        for (clock in clocks)
            a.push(clock);

        return a;
    }

    private override function afterChildrenInitialized(model:ReadOnlyModel, getBehaviour:Void->IBehaviour)
    {
        setOrientation(model.asGenericModel().getOrientation());
    }

    private override function beforeUpdateProcessedByChildren(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        switch event
        {
            case OrientationUpdated:
                setOrientation(model.asGenericModel().getOrientation());
            default:
        }
    }

    private function setOrientation(orientation:PieceColor)
    {
        headerContainer.removeAllComponents(false);
        footerContatiner.removeAllComponents(false);

        if (orientation == White)
        {
            headerContainer.addComponent(clocks.get(Black));
            headerContainer.addComponent(usernameLabels.get(Black));
            footerContatiner.addComponent(usernameLabels.get(White));
            footerContatiner.addComponent(clocks.get(White));
        }
        else
        {
            headerContainer.addComponent(clocks.get(White));
            headerContainer.addComponent(usernameLabels.get(White));
            footerContatiner.addComponent(usernameLabels.get(Black));
            footerContatiner.addComponent(clocks.get(Black));
        }
    }

    @:bind(this, UIEvent.RESIZE)
    private function onResized(e) 
    {
        for (color in PieceColor.createAll())
        {
            usernameLabels.get(color).height = 0.08 * this.height;
            clocks.get(color).height = 0.055 * this.height;
        }
    }
}