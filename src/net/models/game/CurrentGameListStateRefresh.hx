package net.models.game;

import jsonmodel.IJsonUnserializableMacro;

/** All ongoing games, the latest started first **/
class CurrentGameListStateRefresh implements IJsonUnserializableMacro
{
    public var games:Array<GameSummaryPublic>;
}
