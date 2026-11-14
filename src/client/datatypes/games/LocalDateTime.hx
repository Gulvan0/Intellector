package client.datatypes.games;

/** A `DateTime` operand: a date, or a date with a time, of the viewer's wall clock **/
class LocalDateTime
{
    public final year:Int;
    /** 1-12 **/
    public final month:Int;
    public final day:Int;
    /** Null for a date without a time **/
    public final time:Null<TimeOfDay>;

    public function new(year:Int, month:Int, day:Int, ?time:TimeOfDay)
    {
        this.year = year;
        this.month = month;
        this.day = day;
        this.time = time;
    }
}
