package dict.utils;

private enum SimpleTimeInterval
{
    LessThanASecond;
    Seconds(cnt:Int);
    Minutes(cnt:Int);
    Hours(cnt:Int);
    Days(cnt:Int);
    Years(cnt:Int);
}

class TimePhrases
{
    public static function getTimePassedString(secsPassed:Float):String
    {
        var interval:SimpleTimeInterval = secsToInterval(secsPassed);

        return switch Preferences.language.get()
        {
            case EN: getTimePassedEnglish(interval);
            case RU: getTimePassedRussian(interval);
        }
    }

    private static function secsToInterval(secs:Float):SimpleTimeInterval
    {
        if (secs < 1)
            return LessThanASecond;

        var seconds:Int = Math.floor(secs);

        if (seconds < 60)
            return Seconds(seconds);

        var mins:Int = Math.floor(seconds / 60);

        if (mins < 60)
            return Minutes(mins);

        var hours:Int = Math.floor(mins / 60);

        if (hours < 24)
            return Hours(hours);

        var days:Int = Math.floor(hours / 24);

        if (days < 365)
            return Days(days);

        var years:Int = Math.floor(days / 365);

        return Years(years);
    }

    private static function getTimePassedEnglish(interval:SimpleTimeInterval):String
    {
        return switch interval 
        {
            case LessThanASecond: "Just now";
            case Seconds(1): "A second ago";
            case Seconds(cnt): '$cnt seconds ago';
            case Minutes(1): "A minute ago";
            case Minutes(cnt): '$cnt minutes ago';
            case Hours(1): "An hour ago";
            case Hours(cnt): '$cnt hours ago';
            case Days(1): "Yesterday";
            case Days(cnt): '$cnt days ago';
            case Years(1): "A year ago";
            case Years(cnt): '$cnt years ago';
        }
    }

    private static function getTimePassedRussian(interval:SimpleTimeInterval):String
    {
        return switch interval 
        {
            case LessThanASecond: "Только что";
            case Seconds(1): "Секунду назад";
            case Seconds(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt секунд назад';
            case Seconds(cnt) if (cnt % 10 == 1): '$cnt секунду назад';
            case Seconds(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt секунды назад';
            case Seconds(cnt): '$cnt секунд назад';
            case Minutes(1): "Минуту назад";
            case Minutes(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt минут назад';
            case Minutes(cnt) if (cnt % 10 == 1): '$cnt минуту назад';
            case Minutes(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt минуты назад';
            case Minutes(cnt): '$cnt минут назад';
            case Hours(1): "Час назад";
            case Hours(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt часов назад';
            case Hours(cnt) if (cnt % 10 == 1): '$cnt час назад';
            case Hours(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt часа назад';
            case Hours(cnt): '$cnt часов назад';
            case Days(1): "Вчера";
            case Days(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt дней назад';
            case Days(cnt) if (cnt % 10 == 1): '$cnt день назад';
            case Days(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt дня назад';
            case Days(cnt): '$cnt дней назад';
            case Years(1): "Год назад";
            case Years(cnt) if (cnt % 100 >= 11 && cnt % 100 <= 14): '$cnt лет назад';
            case Years(cnt) if (cnt % 10 == 1): '$cnt год назад';
            case Years(cnt) if (cnt % 10 >= 2 && cnt % 10 <= 4): '$cnt года назад';
            case Years(cnt): '$cnt лет назад';
        }
    }
}