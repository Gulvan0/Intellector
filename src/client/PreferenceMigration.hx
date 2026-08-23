package client;

import js.Cookie;
import haxefolio.preferences.Preference;

class PreferenceMigration
{
    public static function run():Void
    {
        var cookies:Map<String, String> = Cookie.all();

        migrateOption(cookies, "lang", Preferences.language, ["EN" => "en", "RU" => "ru"]);
        migrateOption(cookies, "marking", Preferences.boardCoordinates, ["None" => "none", "Side" => "files_only", "Over" => "all"]);
        migrateToggle(cookies, "Premoves", Preferences.premoveEnabled);
        migrateOption(cookies, "BranchingType", Preferences.branchingTabType, ["Tree" => "tree", "Outline" => "outline", "PlainText" => "plain_text"]);
        migrateToggle(cookies, "BranchingShowTurnColor", Preferences.branchingTurnColorIndicators);
        migrateToggle(cookies, "SilentChallenges", Preferences.silentChallenges);
        migrateOption(cookies, "AutoScrollOnMoveReceived", Preferences.followLatestMove, ["Always" => "always", "OwnGameOnly" => "own_game_only", "Never" => "never"]);
    }

    private static function migrateOption(cookies:Map<String, String>, cookieName:String, preference:Preference<String>, valueMap:Map<String, String>):Void
    {
        var rawValue:Null<String> = cookies.get(cookieName);

        if (rawValue == null)
            return;

        var mappedValue:Null<String> = valueMap.get(rawValue);

        if (mappedValue != null)
            preference.setQuiet(mappedValue);

        Cookie.remove(cookieName);
    }

    private static function migrateToggle(cookies:Map<String, String>, cookieName:String, preference:Preference<Bool>):Void
    {
        var rawValue:Null<String> = cookies.get(cookieName);

        if (rawValue == null)
            return;

        preference.setQuiet(rawValue == "true");
        Cookie.remove(cookieName);
    }
}
