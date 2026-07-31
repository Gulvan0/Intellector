package client.ui.home;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class HomePage extends PageBase
{
    public function new()
    {
        super();
    }

    private override function init():Void
    {
        var titleKey:String = LocaleUtils.localeBinding("intellector.home.title");
        setTitle(titleKey);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey);
        addComponent(label);
    }
}
