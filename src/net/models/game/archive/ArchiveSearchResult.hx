package net.models.game.archive;

import jsonmodel.IJsonUnserializableMacro;

class ArchiveSearchResult implements IJsonUnserializableMacro
{
    public var games:Array<ArchiveGameRow>;
    public var total:Int;
}
