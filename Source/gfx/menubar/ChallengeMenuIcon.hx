package gfx.menubar;

import net.shared.utils.MathUtils;
import ds.IntHashSet;
import ds.Set;
import utils.AssetManager;
import haxe.ui.components.Image;

@:xml('
    <image width="25" height="25">
        <image width="25" height="25" id="actualImage" />
        <absolute id="notificationContainer" width="25" height="25" hidden="true">
            <box id="roundBox" width="12.5" height="12.5" style="background-color: red;border-radius: 8px;padding: 2px 2px;" top="-3" left="18" />
        </absolute>
    </image>
')
class ChallengeMenuIcon extends Image
{
    private var unreadChallengeIDs:IntHashSet = new IntHashSet(1024, 128);

    private var incomingChallengeIDs:IntHashSet = new IntHashSet(1024, 128);
    private var outgoingChallengeIDs:IntHashSet = new IntHashSet(1024, 128);

    private override function set_width(value:Float):Float 
    {
        if (actualImage != null)
            actualImage.width = value;
        if (notificationContainer != null)
            notificationContainer.width = value;

        if (roundBox != null)
        {
            roundBox.width = value / 2;
            roundBox.left = value * 0.54;
    
            var newStyle = roundBox.customStyle.clone();
            newStyle.paddingLeft = value * 0.08;
            newStyle.paddingRight = value * 0.08;
            newStyle.borderRadius = value * 0.32;
            roundBox.customStyle = newStyle;
        }

        return super.set_width(value);
    }

    private override function set_height(value:Float):Float 
    {
        if (actualImage != null)
            actualImage.height = value;
        if (notificationContainer != null)
            notificationContainer.height = value;

        if (roundBox != null)
        {
            roundBox.height = value / 2;
            roundBox.top = -value * 0.12;
    
            var newStyle = roundBox.customStyle.clone();
            newStyle.paddingTop = value * 0.08;
            newStyle.paddingBottom = value * 0.08;
            newStyle.borderRadius = value * 0.32;
            roundBox.customStyle = newStyle;
        }

        return super.set_height(value);
    }

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

    private override function onReady() 
    {
        super.onReady();

        if (actualImage != null)
        {
            actualImage.width = width;
            actualImage.height = height;
        }
        if (notificationContainer != null)
        {
            notificationContainer.width = width;
            notificationContainer.height = height;
        }

        if (roundBox != null)
        {
            roundBox.width = width / 2;
            roundBox.height = height / 2;
            
            roundBox.left = width * 0.54;
            roundBox.top = -height * 0.12;
    
            var newStyle = roundBox.customStyle.clone();
            newStyle.paddingLeft = width * 0.08;
            newStyle.paddingRight = width * 0.08;
            newStyle.paddingTop = height * 0.08;
            newStyle.paddingBottom = height * 0.08;
            newStyle.borderRadius = MathUtils.avg(width, height) * 0.32;
            roundBox.customStyle = newStyle;
        }
    }

    public function new()
    {
        super();
        actualImage.resource = AssetManager.challengesMenuIconPath(Empty);
    }
}