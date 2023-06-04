package gfx.game.live;

import net.Requests;
import gfx.Dialogs;
import gfx.popups.FullSpectatorListDialog;
import haxe.ui.components.Link;
import haxe.ui.events.MouseEvent;
import dict.Dictionary;
import gfx.game.interfaces.IGameComponent;
import haxe.ui.containers.Card;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/game/live/spectator_list.xml"))
class SpectatorList extends Card implements IGameComponent
{
    private static inline final MAX_DISPLAYED_LOGINS_COUNT:Int = 8;

    private var visibleSpectatorLinks:Map<String, Link> = [];
    private var allSpectatorLogins:Array<String> = [];

    private function updateSpectatorCount()
    {
        var newCount:Int = allSpectatorLogins.length;
        headerLabel.text = Dictionary.getPhrase(SPECTATOR_COUNT_HEADER(newCount));
        ellipsisLink.hidden = newCount <= MAX_DISPLAYED_LOGINS_COUNT;
    }

    private function addSpectator(login:String)
    {
        if (visibleSpectatorLinks.exists(login))
            return;

        allSpectatorLogins.push(login);
        updateSpectatorCount();

        if (allSpectatorLogins.length < MAX_DISPLAYED_LOGINS_COUNT)
        {
            var link:Link = new Link();
            link.styleNames = "spectators-spec-link";
            link.text = login;
            link.onClick = e -> {Requests.getMiniProfile(login);};

            visibleSpectatorLinks.set(login, link);
            spectatorsBox.addComponentAt(link, allSpectatorLogins.length);
        }
    }

    private function removeSpectator(login:String)
    {
        allSpectatorLogins.remove(login);
        updateSpectatorCount();

        if (!visibleSpectatorLinks.exists(login))
            return;

        spectatorsBox.removeComponent(visibleSpectatorLinks.get(login));
        visibleSpectatorLinks.remove(login);
    }

    @:bind(ellipsisLink, MouseEvent.CLICK)
    private function onEllipsisClicked(e)
    {
        Dialogs.getQueue().add(new FullSpectatorListDialog(allSpectatorLogins));
    }

    public function new()
    {
        super();
    }
}