package gfx.menubar;

import ds.IntHashSet;
import ds.Set;
import utils.AssetManager;
import haxe.ui.components.Image;

@:xml('
    <image width="25" height="25">
        <image width="25" height="25" id="actualImage" />
        <absolute id="notificationContainer" width="25" height="25" hidden="true">
            <box width="12.5" height="12.5" style="background-color: red;border-radius: 8px;padding: 2px 2px;" top="-3" left="18" />
        </absolute>
    </image>
')
class ChallengeMenuIcon extends Image
{
    private var unreadChallengeIDs:IntHashSet = new IntHashSet(1024, 128);

    private var incomingChallengeIDs:IntHashSet = new IntHashSet(1024, 128);
    private var outgoingChallengeIDs:IntHashSet = new IntHashSet(1024, 128);

    private function updateMode() 
    {
        var mode:ChallengesIconMode;

        if (incomingChallengeIDs.isEmpty())
            if (outgoingChallengeIDs.isEmpty())
                mode = Empty;
            else
                mode = HasOutgoing;
        else
            if (outgoingChallengeIDs.isEmpty())
                mode = HasIncoming;
            else
                mode = HasBoth;

        actualImage.resource = AssetManager.challengesMenuIconPath(mode);
    }

    private function addUnread(id:Int)
    {
        if (unreadChallengeIDs.contains(id))
            return;

        unreadChallengeIDs.set(id);
        notificationContainer.hidden = unreadChallengeIDs.isEmpty();
    }

    private function removeUnread(id:Int)
    {
        unreadChallengeIDs.unset(id);
        notificationContainer.hidden = unreadChallengeIDs.isEmpty();
    }

    public function resetUnread() 
    {
        unreadChallengeIDs.clear();
        notificationContainer.hidden = true;
    }

    public function clear() 
    {
        resetUnread();
        incomingChallengeIDs.clear();
        outgoingChallengeIDs.clear();
        actualImage.resource = AssetManager.challengesMenuIconPath(Empty);
    }

    public function addIncoming(id:Int, trackAsUnread:Bool) 
    {
        incomingChallengeIDs.set(id);
        updateMode();
        if (trackAsUnread)
            addUnread(id);
    }

    public function removeIncoming(id:Int) 
    {
        incomingChallengeIDs.unset(id);
        updateMode();
        removeUnread(id);
    }

    public function addOutgoing(id:Int) 
    {
        outgoingChallengeIDs.set(id);
        updateMode();
    }

    public function removeOutgoing(id:Int) 
    {
        outgoingChallengeIDs.unset(id);
        updateMode();
    }

    public function new()
    {
        super();
        actualImage.resource = AssetManager.challengesMenuIconPath(Empty);
    }
}