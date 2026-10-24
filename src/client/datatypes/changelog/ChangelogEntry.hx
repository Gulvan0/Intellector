package client.datatypes.changelog;

class ChangelogEntry
{
    public final year:Int;
    public final month:Int;
    public final day:Int;

    /** 1-based, among the entries of the same date, oldest first; null when the date has a single entry **/
    public final sameDayNumber:Null<Int>;

    private final titles:Map<String, String>;
    private final descriptions:Map<String, Array<String>>;

    /** `titles` and `descriptions` are keyed by language; `descriptions` is empty for a title-only entry **/
    public function new(year:Int, month:Int, day:Int, sameDayNumber:Null<Int>, titles:Map<String, String>, descriptions:Map<String, Array<String>>)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.sameDayNumber = sameDayNumber;
        this.titles = titles;
        this.descriptions = descriptions;
    }

    public function hasDescription():Bool
    {
        return descriptions.iterator().hasNext();
    }

    /** Falls back to English when `language` has no translation **/
    public function title(language:String):String
    {
        return titles.exists(language) ? titles[language] : titles["en"];
    }

    /** Falls back to English when `language` has no translation; every language has as many paragraphs as English **/
    public function paragraphs(language:String):Array<String>
    {
        return descriptions.exists(language) ? descriptions[language] : descriptions["en"];
    }
}
