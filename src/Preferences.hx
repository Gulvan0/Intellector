import haxefolio.preferences.PreferenceRegistry;

class Preferences extends PreferenceRegistry
{
    public static final language = PreferenceRegistry.locale("general", "language");
    public static final darkMode = PreferenceRegistry.toggle("general", "darkmode", false);
}
