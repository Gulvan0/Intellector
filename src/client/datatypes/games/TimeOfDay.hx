package client.datatypes.games;

class TimeOfDay
{
    /** 0-23 **/
    public final hours:Int;
    public final minutes:Int;
    public final seconds:Int;

    public function new(hours:Int, minutes:Int, seconds:Int)
    {
        this.hours = hours;
        this.minutes = minutes;
        this.seconds = seconds;
    }
}
