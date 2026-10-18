package net.models.game;

import net.models.common.TimeControlKind;

class GameSearchCounts
{
	public var time_control_kinds:Map<TimeControlKind, Int>;
	public var rated:GameSearchRatedCounts;
}
