import haxe.ui.components.Label;
import haxefolio.HaxeFolioApp;
import haxefolio.HaxeFolioConfig;
import haxefolio.HaxeFolioConfigBuilder;

class Main
{
    public static function main():Void
    {
        var settingsWidget:Label = new Label();
        settingsWidget.text = "⚙";
        settingsWidget.onClick = _ -> HaxeFolioApp.showPreferences();

        var config:HaxeFolioConfig = HaxeFolioConfigBuilder.init("haxefolio-example", Preferences)
            .setAppIcon("assets/favicons/normal.png")
            .setSiteName("HaxeFolio Example")
            .setMenuCollapseWidth(900)
            .setDefaultTitleKey("app.default_title")

            .addPage("home", params -> new HomePage(), true)
            .addPage("user/{login}", params -> new UserPage(params["login"]))

            .addLeftMenubarItem(SiteName)
            .addLeftMenubarItem(NormalMenu("navigation", []))
            .addNormalMenuItem("navigation", "home", NavigateTo(() -> "home"))

            .addRightMenubarItem(NormalMenu("help", []))
            .addNormalMenuItem("help", "about", Execute(showAboutDialog))
            .addRightMenubarItem(Widget(settingsWidget, true))

            .addSidebarExtraGroupItem("account", "greet", Execute(showAboutDialog))

            .addLocale("en", "English")
            .addLocale("de", "Deutsch")

            .setPreferenceTabIcons(["general" => "assets/images/general.svg"])
            .setLanguagePreference(Preferences.language)

            .buildConfig();

        HaxeFolioApp.init(config);
    }

    private static function showAboutDialog():Void
    {
        trace("HaxeFolio Example App");
    }
}
