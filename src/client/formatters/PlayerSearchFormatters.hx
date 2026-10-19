package client.formatters;

import client.datatypes.player.PlayerRelation;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;

class PlayerSearchFormatters
{
    /** `12 players` **/
    public static function count(count:Int):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(Plurals.key("intellector.overlay.player_search.count", count, LocaleManager.instance.language)), count);
    }

    /** `No players match “ale”` **/
    public static function noMatch(query:String):String
    {
        return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.overlay.player_search.none"), query);
    }

    /** A locale binding, null for none **/
    public static function relation(relation:PlayerRelation):Null<String>
    {
        return switch relation {
            case Unrelated: null;
            case FollowsYou: LocaleUtils.localeBinding("intellector.overlay.player_search.relation.follows_you");
            case YouFollow(_): LocaleUtils.localeBinding("intellector.overlay.player_search.relation.you_follow");
            case Friends(_): LocaleUtils.localeBinding("intellector.overlay.player_search.relation.friends");
        }
    }
}
