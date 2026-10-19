package client.formatters;

import client.datatypes.player.PlayerRelation;
import client.datatypes.player.PlayerRole;
import client.datatypes.player.PlayerStatus;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

class ProfileFormatters
{
    private static inline final HOUR_MS:Float = 60 * 60 * 1000;
    private static inline final DAY_MS:Float = 24 * HOUR_MS;
    private static inline final MONTH_DAYS:Float = 30.44;
    private static inline final YEAR_DAYS:Float = 365.25;

    /** `12 March 2024`, local time **/
    public static function longDate(unixMs:Float):String
    {
        var date:Date = Date.fromTime(unixMs);
        return '${date.getDate()} ${month(date, "long")} ${date.getFullYear()}';
    }

    /** `12 Mar`, with the year unless it's the current one **/
    public static function shortDate(unixMs:Float, nowMs:Float):String
    {
        var date:Date = Date.fromTime(unixMs);
        var sameYear:Bool = date.getFullYear() == Date.fromTime(nowMs).getFullYear();
        return sameYear ? '${date.getDate()} ${month(date, "short")}' : '${date.getDate()} ${month(date, "short")} ${date.getFullYear()}';
    }

    /** `12 Mar 2025` **/
    public static function shortDateWithYear(unixMs:Float):String
    {
        var date:Date = Date.fromTime(unixMs);
        return '${date.getDate()} ${month(date, "short")} ${date.getFullYear()}';
    }

    /** `Mar 2025` **/
    public static function monthAndYear(unixMs:Float):String
    {
        var date:Date = Date.fromTime(unixMs);
        return '${month(date, "short")} ${date.getFullYear()}';
    }

    /** `14:05`, local time **/
    public static function timeOfDay(unixMs:Float):String
    {
        return DateTools.format(Date.fromTime(unixMs), "%H:%M");
    }

    /** `2 years ago`, in the largest whole unit from years down to hours **/
    public static function ago(elapsedMs:Float):String
    {
        var hours:Int = Math.floor(elapsedMs / HOUR_MS);
        var days:Int = Math.floor(elapsedMs / DAY_MS);
        var months:Int = Math.floor(days / MONTH_DAYS);
        var years:Int = Math.floor(days / YEAR_DAYS);

        if (years >= 1)
            return counted("intellector.common.ago.years", years);
        if (months >= 1)
            return counted("intellector.common.ago.months", months);
        if (days >= 1)
            return counted("intellector.common.ago.days", days);
        return counted("intellector.common.ago.hours", Std.int(Math.max(hours, 1)));
    }

    /** `Joined 12 March 2024 (2 years ago)` **/
    public static function joined(joinedAtMs:Float, nowMs:Float):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.joined"), longDate(joinedAtMs), ago(nowMs - joinedAtMs));
    }

    /** `Last seen 5 hours ago` **/
    public static function lastSeen(lastActiveMs:Float, nowMs:Float):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.last_seen"), ago(nowMs - lastActiveMs));
    }

    /** The relation line under the status, null for none **/
    public static function relation(relation:PlayerRelation):Null<String>
    {
        return switch relation {
            case Unrelated: null;
            case FollowsYou: resolve("intellector.profile.relation.follows_you");
            case YouFollow(sinceMs): LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.relation.you_follow"), longDate(sinceMs));
            case Friends(sinceMs): LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.profile.relation.friends"), longDate(sinceMs));
        }
    }

    /** A locale binding **/
    public static function status(status:PlayerStatus):String
    {
        return LocaleUtils.localeBinding('intellector.profile.status.${status.getName().toLowerCase()}');
    }

    /** A locale binding **/
    public static function role(role:PlayerRole):String
    {
        return LocaleUtils.localeBinding(switch role {
            case Admin: "intellector.profile.role.admin";
            case AnacondaDeveloper: "intellector.profile.role.anaconda_developer";
        });
    }

    private static function month(date:Date, form:String):String
    {
        return resolve('intellector.common.month.$form.${date.getMonth() + 1}');
    }

    private static function counted(key:String, count:Int):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(Plurals.key(key, count, LocaleManager.instance.language)), count);
    }

    private static function resolve(key:String):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(key));
    }
}
