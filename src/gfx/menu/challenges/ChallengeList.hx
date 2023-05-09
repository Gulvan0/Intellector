package gfx.menu.challenges;

import assets.Audio;
import gfx.popups.IncomingChallengeDialog;
import browser.Blinker;
import net.INetObserver;
import GlobalBroadcaster.IGlobalEventObserver;
import net.shared.ServerEvent;
import GlobalBroadcaster.GlobalEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.Menu.MenuEvent;
import haxe.ui.containers.Stack;
import struct.ChallengeParams;
import haxe.ui.containers.ListView;
import net.shared.dataobj.ChallengeData;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/menu/challenge_list.xml'))
class ChallengeList extends Menu implements IGlobalEventObserver implements INetObserver
{
    public var flagIcon:ChallengeMenuIcon;
    private var menuShown:Bool = false;

    private var entryDataByID:Map<Int, ChallengeEntryData> = [];
    private var idsByOwnerLogin:Map<String, Array<Int>> = [];
    private var ownIDs:Array<Int> = [];

    @:bind(this, MenuEvent.MENU_OPENED)
    private function onOpened(e)
    {
        menuShown = true;
        flagIcon.resetUnread();
    }

    @:bind(this, MenuEvent.MENU_CLOSED)
    private function onClosed(e)
    {
        menuShown = false;
    }

    private function updateItemCount(newItemCount:Int)
    {
        if (newItemCount == 0)
        {
            stack.selectedIndex = 0;
            stack.height = 30;
        }
        else 
        {
            stack.selectedIndex = 1;
            stack.height = Math.min(newItemCount * 102, 250);
        }
    }

    public function appendEntry(data:ChallengeData)
    {
        var entryData = new ChallengeEntryData(data, this);
        entryDataByID.set(entryData.id, entryData);
        actualList.dataSource.add(entryData);

        updateItemCount(actualList.dataSource.size);

        if (!LoginManager.isPlayer(data.ownerLogin))
        {
            var ownerLogin:String = data.ownerLogin.toLowerCase();
            if (idsByOwnerLogin.exists(ownerLogin))
                idsByOwnerLogin.get(ownerLogin).push(data.id);
            else
                idsByOwnerLogin.set(ownerLogin, [data.id]);
            flagIcon.addIncoming(data.id, !menuShown);
        }
        else
        {
            ownIDs.push(data.id);
            flagIcon.addOutgoing(data.id);
        }
    }

    public function clearEntries()
    {
        flagIcon.clear();
        actualList.dataSource.clear();
        updateItemCount(0);
        entryDataByID = [];
        idsByOwnerLogin = [];
        ownIDs = [];
    }

    public function removeEntryByID(id:Int)
    {
        var data:Null<ChallengeEntryData> = entryDataByID.get(id);

        if (data == null)
            return;

        actualList.dataSource.remove(data);
        updateItemCount(actualList.dataSource.size);

        entryDataByID.remove(id);

        var isOwn:Bool = ownIDs.remove(id);

        if (!isOwn)
        {
            for (login => list in idsByOwnerLogin.keyValueIterator())
            {
                list.remove(id);
                if (Lambda.empty(list))
                    idsByOwnerLogin.remove(login);
            }

            flagIcon.removeIncoming(id);
        }
        else
            flagIcon.removeOutgoing(id);
    }

    public function removeEntriesByPlayer(login:String)
    {
        var playerIDs:Null<Array<Int>> = idsByOwnerLogin.get(login.toLowerCase());
        if (playerIDs != null)
            for (id in playerIDs.copy())
                removeEntryByID(id);
    }

    public function removeOwnEntries()
    {
        for (id in ownIDs.copy())
            removeEntryByID(id);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedOut:
                clearEntries();
            case IncomingChallengesBatch(incomingChallenges):
                for (info in incomingChallenges)
                    appendEntry(info);
            default:
        }
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case CreateChallengeResult(Success(data)):
                appendEntry(data);
            case DirectChallengeCancelled(id):
                removeEntryByID(id);
            case DirectChallengeDeclined(id):
                removeEntryByID(id);
            case IncomingDirectChallenge(data):
                appendEntry(data);
            default:
        }
    }

    public function new() 
    {
        super();

        flagIcon = new ChallengeMenuIcon();
        icon = flagIcon;

        GlobalBroadcaster.addObserver(this);
        Networker.addObserver(this);
    }
}