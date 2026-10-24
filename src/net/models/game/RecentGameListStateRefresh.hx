package net.models.game;

import jsonmodel.IJsonUnserializableMacro;

/** The latest finished non-aborted games matching the channel's filter, the latest ended first **/
class RecentGameListStateRefresh implements IJsonUnserializableMacro
{
    public var games:Array<GameSummaryPublic>;
}
