package gfx.menubar;

import struct.ChallengeParams;
import haxe.ui.containers.ListView;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/menubar/challenge_list.xml'))
class ChallengeList extends ListView
{
    private var indexByID:Map<Int, Int> = [];
    private var idsByOwnerLogin:Map<String, Array<Int>> = [];
    private var ownIDs:Array<Int> = [];

    private var currentMode(default, set):ChallengesIconMode = Empty;
    public var onModeChanged:ChallengesIconMode->Void;

    private function set_currentMode(v:ChallengesIconMode):ChallengesIconMode
    {
        if (currentMode == v)
            return v;

        currentMode = v;
        onModeChanged(v);
        return v;
    }

    public function appendEntry(id:Int, params:ChallengeParams)
    {
        dataSource.add({id: id, params: params});

        indexByID.set(id, dataSource.size - 1);

        if (!LoginManager.isPlayer(params.ownerLogin))
        {
            var ownerLogin:String = params.ownerLogin.toLowerCase();
            if (idsByOwnerLogin.exists(ownerLogin))
                idsByOwnerLogin.get(ownerLogin).push(id);
            else
                idsByOwnerLogin.set(ownerLogin, [id]);
            if (currentMode == Empty)
                currentMode = HasIncoming;
            else if (currentMode == HasOutgoing)
                currentMode = HasBoth;
        }
        else
        {
            ownIDs.push(id);
            if (currentMode == Empty)
                currentMode = HasOutgoing;
            else if (currentMode == HasIncoming)
                currentMode = HasBoth;
        }
    }

    private function removeEntry(index:Int)
    {
        dataSource.removeAt(index);
    }

    public function clearEntries()
    {
        dataSource.clear();
        indexByID = [];
        idsByOwnerLogin = [];
        ownIDs = [];
        currentMode = Empty;
    }

    public function removeEntryByID(id:Int)
    {
        var index:Null<Int> = indexByID.get(id);

        if (index == null)
            return;

        dataSource.removeAt(index);

        indexByID.remove(id);

        var isOwn:Bool = ownIDs.remove(id);

        if (isOwn && Lambda.empty(ownIDs))
            if (currentMode == HasOutgoing)
                currentMode = Empty;
            else if (currentMode == HasBoth)
                currentMode = HasIncoming;

        if (!isOwn)
        {
            for (login => list in idsByOwnerLogin.keyValueIterator())
            {
                list.remove(id);
                if (Lambda.empty(list))
                    idsByOwnerLogin.remove(login);
            }

            if (Lambda.empty(idsByOwnerLogin))
                if (currentMode == HasIncoming)
                    currentMode = Empty;
                else if (currentMode == HasBoth)
                    currentMode = HasOutgoing;
        }
    }

    public function removeEntriesByPlayer(login:String)
    {
        for (id in idsByOwnerLogin.get(login.toLowerCase()))
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
    }
}