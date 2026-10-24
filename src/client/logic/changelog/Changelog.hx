package client.logic.changelog;

import client.datatypes.changelog.ChangelogEntry;
import haxe.Resource;
import jsonmodel.UnserializableArray;
import jsonmodel.UnserializerInput;
import net.models.changelog.ChangelogEntryRecord;
import net.models.changelog.mappers.ChangelogEntryMapper;

class Changelog
{
    /** The embedded `changelog.json`, newest first **/
    public static function load():Array<ChangelogEntry>
    {
        var records:UnserializableArray<ChangelogEntryRecord> = new UnserializableArray(UnserializerInput.Str(Resource.getString("changelog")));
        return ChangelogEntryMapper.recordsToDatatypes(records.parsed);
    }
}
