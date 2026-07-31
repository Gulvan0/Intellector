package client.ui.profile;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class ProfilePage extends PageBase
{
    private final login:String;

    public function new(login:String)
    {
        super();
        this.login = login;
    }

    private override function init():Void
    {
        var titleKey:String = LocaleUtils.localeBinding("intellector.profile.title");
        setTitle(titleKey, login);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, login);
        addComponent(label);
    }
}
