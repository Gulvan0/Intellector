package client.ui.common;

import client.datatypes.player.PlayerStatus;
import haxe.ui.containers.Box;

using client.ui.ComponentExtension;

/** A player's status as a 10px dot: filled while playing, online or away, a faint ring while offline **/
class StatusDot extends Box
{
    public function new(status:PlayerStatus)
    {
        super();
        addClass(StyleClass.STATUS_DOT);
        verticalAlign = "center";
        setStatus(status);
    }

    public function setStatus(status:PlayerStatus):Void
    {
        this.setClass(StyleClass.STATUS_DOT_PLAYING, status == Playing);
        this.setClass(StyleClass.STATUS_DOT_ONLINE, status == Online);
        this.setClass(StyleClass.STATUS_DOT_AWAY, status == Away);
        this.setClass(StyleClass.STATUS_DOT_OFFLINE, status == Offline);
    }
}
