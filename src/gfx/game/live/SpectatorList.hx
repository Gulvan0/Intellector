package gfx.game.live;

import hx.strings.collection.SortedStringSet;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameScreenGetters;
import gfx.game.events.ModelUpdateEvent;
import haxe.ui.core.Component;
import net.Requests;
import gfx.Dialogs;
import gfx.popups.FullSpectatorListDialog;
import haxe.ui.components.Link;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Card;

using gfx.game.models.CommonModelExtractors;

@:build(haxe.ui.ComponentBuilder.build("assets/layouts/game/live/spectator_list.xml"))
class SpectatorList extends Card implements IGameComponent
{
    private static inline final MAX_DISPLAYED_LOGINS_COUNT:Int = 8;

    private var allSpectatorLogins:SortedStringSet;

    private function updateSpectatorCount()
    {
        var newCount:Int = allSpectatorLogins.size;
        headerLabel.text = Dictionary.getPhrase(SPECTATOR_COUNT_HEADER(newCount));
        ellipsisLink.hidden = newCount <= MAX_DISPLAYED_LOGINS_COUNT;
    }

    private function updateSpectators(logins:Array<String>)
    {
        allSpectatorLogins = new SortedStringSet(logins);
        updateSpectatorCount();

        var i:Int = 0;
        for (login in allSpectatorLogins)
        {
            if (i >= MAX_DISPLAYED_LOGINS_COUNT)
                break;

            var link:Link = new Link();
            link.styleNames = "spectators-spec-link";
            link.text = login;
            link.onClick = e -> {Requests.getMiniProfile(login);};
            spectatorsBox.addComponentAt(link, i);

            i++;
        }
    }

    @:bind(ellipsisLink, MouseEvent.CLICK)
    private function onEllipsisClicked(e)
    {
        Dialogs.getQueue().add(new FullSpectatorListDialog(allSpectatorLogins));
    }

    public function init(model:ReadOnlyModel, getters:IGameScreenGetters) 
    {
        updateSpectators(model.asGameModel().getSpectators());
    }

	public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent) 
    {
        switch event 
        {
            case SpectatorListUpdated:
                updateSpectators(model.asGameModel().getSpectators());
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

    public function new()
    {
        super();
    }
}