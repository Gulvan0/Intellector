import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.layouts.VerticalLayout;
import haxefolio.HaxeFolioApp;
import haxefolio.PageBase;

class UserPage extends PageBase
{
    private var login:String;

    public function new(login:String)
    {
        super();
        this.login = login;
    }

    private override function init():Void
    {
        setTitle("page.user.title", login);

        layout = new VerticalLayout();

        var currentPageLabel:Label = new Label();
        currentPageLabel.text = 'User Page (login: $login)';
        addComponent(currentPageLabel);

        var goToHomePageButton:Button = new Button();
        goToHomePageButton.text = "Go to Home Page";
        goToHomePageButton.onClick = _ -> HaxeFolioApp.navigateTo("home");
        addComponent(goToHomePageButton);
    }
}
