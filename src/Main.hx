import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;

class Main
{
    public static function main():Void
    {
        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("intellector", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("Intellector")
            .setDebounceMs(100)
            .addLocale("en", "English")
            .addLocale("ru", "Русский")
            .setLanguagePreference(Preferences.language)
            .buildConfig();

        HaxeFolioApp.init(config);
    }
}
