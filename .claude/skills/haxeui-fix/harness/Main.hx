import haxe.ui.ComponentBuilder;
import haxe.ui.HaxeUIApp;

/*
    Shows repro.xml (copied next to this file by build_repro.sh) as the whole page, on the default
    theme and nothing else, so that the repro behaves the same for an upstream maintainer.
*/
class Main
{
    public static function main():Void
    {
        var app:HaxeUIApp = new HaxeUIApp();
        app.ready(() -> {
            app.addComponent(ComponentBuilder.fromFile("repro.xml"));
            app.start();
        });
    }
}
