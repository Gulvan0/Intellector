package net.shared.utils;

abstract UnixTimestamp(Float)
{
    public static function fromUnixMilliseconds(ms:Float)
    {
        return new UnixTimestamp(ms);
    }

    public static function fromUnixSeconds(secs:Float)
    {
        return fromUnixMilliseconds(secs * 1000);
    }

    /**
        May have precision issues, prefer other constructors
    **/
    public static function fromDate(date:Date)
    {
        return fromUnixMilliseconds(date.getTime());
    }

    public static function now()
    {
        #if sys
        return fromUnixSeconds(Sys.time());
        #else
        return fromDate(Date.now());
        #end
    }

    public function toUnixMilliseconds():Float
    {
        return this;
    }

    public function toUnixSeconds():Float
    {
        return toUnixMilliseconds() / 1000;
    }

    public function toDate():Date
    {
        return Date.fromTime(toUnixMilliseconds());
    }

    public function format(dateTimeFormat:DateTimeFormat):String
    {
        return DateTools.format(toDate(), dateTimeFormat);
    }

    public function addMilliseconds(ms:Float):UnixTimestamp
    {
        return new UnixTimestamp(this + ms);
    }

    public function addSeconds(secs:Float):UnixTimestamp
    {
        return addMilliseconds(secs * 1000);
    }

    public function getIntervalSecsTo(endTimestamp:UnixTimestamp):Float
    {
        return endTimestamp.toUnixSeconds() - toUnixSeconds();
    }

    public function getIntervalMsTo(endTimestamp:UnixTimestamp):Float
    {
        return endTimestamp.toUnixMilliseconds() - toUnixMilliseconds();
    }

    public function getIntervalSecsFrom(startTimestamp:UnixTimestamp):Float
    {
        return startTimestamp.getIntervalSecsTo(abstract);
    }

    public function getIntervalMsFrom(startTimestamp:UnixTimestamp):Float
    {
        return startTimestamp.getIntervalMsTo(abstract);
    }

    public function getIntervalSecsToNow():Float
    {
        return getIntervalSecsTo(UnixTimestamp.now());
    }

    public function getIntervalMsToNow():Float
    {
        return getIntervalMsTo(UnixTimestamp.now());
    }

    public function toString()
    {
        return format(DashDelimitedDayWithTJoinedTime);
    }

    private function new(ms:Float)
    {
        this = ms;
    }
}