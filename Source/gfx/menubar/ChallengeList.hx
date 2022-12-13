package gfx.menubar;

import haxe.ui.events.UIEvent;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.Menu.MenuEvent;
import haxe.ui.containers.Stack;
import struct.ChallengeParams;
import haxe.ui.containers.ListView;
import net.shared.dataobj.ChallengeData;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/menubar/challenge_list.xml'))
class ChallengeList extends Menu
{
    public var flagIcon:ChallengeMenuIcon;
    private var menuShown:Bool = false;

    private var indexByID:Map<Int, Int> = [];
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
        actualList.dataSource.add(new ChallengeEntryData(data, this));

        var newItemCount:Int = actualList.dataSource.size;

        updateItemCount(newItemCount);

        indexByID.set(data.id, newItemCount - 1);

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
        indexByID = [];
        idsByOwnerLogin = [];
        ownIDs = [];
    }

    public function removeEntryByID(id:Int)
    {
        var index:Null<Int> = indexByID.get(id);

        if (index == null)
            return;

        actualList.dataSource.removeAt(index);
        updateItemCount(actualList.dataSource.size);

        indexByID.remove(id);

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
        for (id in ownIDs)
            removeEntryByID(id);
    }

    public function new() 
    {
        super();
        flagIcon = new ChallengeMenuIcon();
        icon = flagIcon;
    }
}