package gfx.game.common;

import gfx.basic_components.Spacers;
import haxe.ui.containers.HBox;
import gfx.game.live.UsernameLabel;
import gfx.game.live.Clock;
import gfx.game.board.util.BoardSize;
import gfx.game.interfaces.IGameComponent;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.board.GameBoard;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;
import net.shared.PieceColor;
import haxe.Timer;
import gfx.game.models.ReadOnlyModel;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.events.GameboardEvent;
import gfx.game.interfaces.IBehaviour;
import haxe.ui.core.Component;

using gfx.game.models.CommonModelExtractors;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/common/compact_board_and_clocks.xml"))
class CompactBoardAndClocks extends GameComponentLayout
{
    private var board:GameBoardWrapper;
    private var usernameLabels:Map<PieceColor, UsernameLabel> = [];
    private var clocks:Map<PieceColor, Clock> = [];

    public function new() 
    {
        super();

        board = new GameBoardWrapper();
        board.percentWidth = 100;
        board.percentHeight = 100;
        content.addComponent(board);

        for (color in PieceColor.createAll())
        {
            var usernameLabel:UsernameLabel = new UsernameLabel(color);
            usernameLabel.percentHeight = 100;
            usernameLabel.verticalAlign = 'center';
            usernameLabels.set(color, usernameLabel);

            var clock:Clock = new Clock(color);
            clock.percentHeight = 100;
            clock.verticalAlign = 'center';
            clocks.set(color, clock);

            var compContainer:HBox = color == White? whiteDetailsBox : blackDetailsBox;
            compContainer.addComponent(usernameLabel);
            compContainer.addComponent(Spacers.fullWidth());
            compContainer.addComponent(clock);
        }
    }

    private function getChildGameComponents():Array<IGameComponent>
    {
        var a:Array<IGameComponent> = [board];

        for (label in usernameLabels)
            a.push(label);

        for (clock in clocks)
            a.push(clock);

        return a;
    }

    private override function afterChildrenInitialized(model:ReadOnlyModel, getBehaviour:Void->IBehaviour)
    {
        setOrientation(model.asGenericModel().getOrientation());
        GlobalBroadcaster.addObserver(this);
    }
    
    private override function destroyLayout()
    {
        GlobalBroadcaster.removeObserver(this);
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
            headerContainer.addComponent(blackDetailsBox);
            footerContatiner.addComponent(whiteDetailsBox);
        }
        else
        {
            headerContainer.addComponent(whiteDetailsBox);
            footerContatiner.addComponent(blackDetailsBox);
        }
    }

    private function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case PreferenceUpdated(Marking):
                var lettersEnabled:Bool = Preferences.marking.get().match(Side | Over);
                doLayout(BoardSize.inverseAspectRatio(lettersEnabled));
            default:
        }
    }

    @:bind(this, UIEvent.RESIZE)
    private function onResized(e) 
    {
        doLayout();
    }

    private function doLayout(?inverseAspectRatio:Float) 
    {
        if (inverseAspectRatio == null)
            inverseAspectRatio = board.inverseAspectRatio();

        var containerWidth:Float = container.width - 2; // account for padding
        var containerHeight:Float = container.height - 2 - 60; // account for padding, header, footer

        var proposedWidth:Float = containerWidth;
        var proposedHeight:Float = proposedWidth * inverseAspectRatio;

        contentContainer.width = containerWidth;

        if (proposedHeight <= containerHeight) 
        {
            content.width = proposedWidth;
            content.height = proposedHeight;
        }
        else 
        {
            content.width = containerHeight / inverseAspectRatio;
            content.height = containerHeight;
        }
    }
}