package client.datatypes.games;

/** A memorable date the `DateTime` selector offers besides the calendar **/
class EventDay
{
    /** A date without a time **/
    public final date:LocalDateTime;
    /** By language code; English is always present **/
    private final names:Map<String, String>;

    public function new(date:LocalDateTime, names:Map<String, String>)
    {
        this.date = date;
        this.names = names;
    }

    public function name(language:String):String
    {
        return names.get(language) ?? names.get("en");
    }
}
