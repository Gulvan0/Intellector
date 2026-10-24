package net.models.changelog.mappers;

import client.datatypes.changelog.ChangelogEntry;

class ChangelogEntryMapper
{
    /** `records` are newest first, so within a date the last one is the first of that day **/
    public static function recordsToDatatypes(records:Array<ChangelogEntryRecord>):Array<ChangelogEntry>
    {
        var entryCountByDate:Map<String, Int> = [];
        for (record in records)
            entryCountByDate[record.date] = (entryCountByDate[record.date] ?? 0) + 1;

        var remainingByDate:Map<String, Int> = entryCountByDate.copy();
        var entries:Array<ChangelogEntry> = [];
        for (record in records)
        {
            var number:Int = remainingByDate[record.date]--;
            var sameDayNumber:Null<Int> = entryCountByDate[record.date] > 1 ? number : null;
            entries.push(recordToDatatype(record, sameDayNumber));
        }
        return entries;
    }

    private static function recordToDatatype(record:ChangelogEntryRecord, sameDayNumber:Null<Int>):ChangelogEntry
    {
        var dateParts:Array<Null<Int>> = record.date.split("-").map(Std.parseInt);
        if (dateParts.length != 3 || dateParts.contains(null))
            throw 'Changelog date must look like yyyy-mm-dd, got "${record.date}"';

        var titles:Map<String, String> = ["en" => record.title.en];
        if (record.title.ru != null)
            titles["ru"] = record.title.ru;

        var descriptions:Map<String, Array<String>> = [];
        if (record.description != null)
        {
            descriptions["en"] = record.description.en;
            if (record.description.ru != null)
            {
                if (record.description.ru.length != record.description.en.length)
                    throw 'Changelog entry ${record.date}: the "ru" description must have as many paragraphs as the "en" one';
                descriptions["ru"] = record.description.ru;
            }
        }

        return new ChangelogEntry(dateParts[0], dateParts[1], dateParts[2], sameDayNumber, titles, descriptions);
    }
}
