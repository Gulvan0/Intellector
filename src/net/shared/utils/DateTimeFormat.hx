package net.shared.utils;

enum abstract DateTimeFormat(String) to String
{
    var DotDelimitedDayWithSeparateTime = "%d.%m.%Y %H:%M:%S";
    var DashDelimitedDayWithSeparateTime = "%d-%m-%Y %H:%M:%S";
    var DashDelimitedDayWithTJoinedTime = "%d-%m-%YT%H:%M:%S";
    var DashDelimitedDayWithUnderscoreJoinedTime = "%d-%m-%Y_%H:%M:%S";
    var DotDelimitedDay = "%d.%m.%Y";
    var DashDelimitedDay = "%d-%m-%Y";
}