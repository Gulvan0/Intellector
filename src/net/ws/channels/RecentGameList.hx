package net.ws.channels;

import easypubsub.IChannel;
import net.models.common.TimeControlKind;

/** Equal filters must be written equally: the kinds sorted and unique, none for any kind **/
class RecentGameList implements IChannel
{
    public var timeControlKinds:Array<TimeControlKind>;
    public var rated:Null<Bool>;
}
