package lib.stdtypes;

class DateTime
{
    public var roughDateTime:Date;
    public var trueSeconds:Float;

    public static function fromIso(isoString:String):DateTime
    {
        var withoutTz:String;
        if (isoString.indexOf("+") != -1)
            withoutTz = isoString.split("+")[0];
        else if (isoString.charAt(isoString.length - 1) == "Z")
            withoutTz = isoString.substr(0, isoString.length - 1);
        else
            withoutTz = isoString;

        var parts:Array<String> = withoutTz.split("T");
        var date:String = parts[0];
        var time:String = parts[1];

        var dateParts:Array<String> = date.split("-");
        var year:Int = Std.parseInt(dateParts[0]);
        var month:Int = Std.parseInt(dateParts[1]);
        var day:Int = Std.parseInt(dateParts[2]);

        var timeParts:Array<String> = time.split(":");
        var hour:Int = Std.parseInt(timeParts[0]);
        var min:Int = Std.parseInt(timeParts[1]);
        var sec:Float = Std.parseFloat(timeParts[2]);

        return new DateTime(year, month, day, hour, min, sec);
    }

    public function new(year:Int, month:Int, day:Int, hour:Int, min:Int, sec:Float)
    {
        this.roughDateTime = new Date(year, month, day, hour, min, Math.floor(sec));
        this.trueSeconds = sec;
    }
}
