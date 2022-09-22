package gfx.profile.data;

import net.shared.EloValue;
import net.shared.TimeControlType;

typedef EloData = {
    var timeControl:TimeControlType;
    var elo:EloValue;
}