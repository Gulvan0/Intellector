package net.shared.dataobj;

import net.shared.utils.UnixTimestamp;

typedef GameEventLogItem = {
    var ts:UnixTimestamp;
    var entry:GameEventLogEntry;
}