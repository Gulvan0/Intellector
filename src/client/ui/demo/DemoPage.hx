package client.ui.demo;

import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.PageBase;

/*
    Temporary: shows what the normal pages can't yet, one showcase per section. Opened by `?p=demo`,
    deleted once the update is finalized.
*/
class DemoPage extends PageBase
{
    private var content:VBox;

    public function new()
    {
        super();
    }

    private override function init():Void
    {
        setTitle("Demo");

        content = new VBox();
        content.percentWidth = 100;
        content.styleString = "spacing: 24px;";
        addComponent(content);

        addShowcase("Challenges", new ChallengesShowcase());
    }

    private function addShowcase(title:String, showcase:Component):Void
    {
        var section:VBox = new VBox();
        section.percentWidth = 100;

        var heading:Label = new Label();
        heading.text = title;
        heading.styleString = "font-size: 18px; font-bold: true;";
        section.addComponent(heading);

        showcase.percentWidth = 100;
        section.addComponent(showcase);
        content.addComponent(section);
    }
}
