import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.HaxeFolioApp;
import haxefolio.PageBase;

class HomePage extends PageBase
{
    private static inline var NOTIFICATION_ICON:String = "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Ccircle cx='8' cy='8' r='7' fill='red'/%3E%3C/svg%3E";

    private override function init():Void
    {
        setTitle("page.home.title");

        layout = new VerticalLayout();

        var currentPageLabel:Label = new Label();
        currentPageLabel.text = "Home Page";
        addComponent(currentPageLabel);

        var loginField:TextField = new TextField();
        loginField.placeholder = "login";
        addComponent(loginField);

        var goToUserPageButton:Button = new Button();
        goToUserPageButton.text = "Go to User Page";
        goToUserPageButton.onClick = _ -> HaxeFolioApp.navigateTo('user/${loginField.text}');
        addComponent(goToUserPageButton);

        var simulateChallengeButton:Button = new Button();
        simulateChallengeButton.text = "Simulate incoming challenge";
        simulateChallengeButton.onClick = _ -> startBlink("page.home.notification.challenge", 1, null, null, null, NOTIFICATION_ICON);
        addComponent(simulateChallengeButton);

        var switchLanguageButton:Button = new Button();
        switchLanguageButton.text = "Switch language (en/de)";
        switchLanguageButton.onClick = _ -> Preferences.language.set(Preferences.language.get() == "en" ? "de" : "en");
        addComponent(switchLanguageButton);
    }
}
