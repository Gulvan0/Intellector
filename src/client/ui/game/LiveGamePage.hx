package client.ui.game;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class LiveGamePage extends PageBase
{
    private final gameId:Int;

    public function new(gameId:Int)
    {
        super();
        this.gameId = gameId;
    }

    private override function init():Void
    {
        var titleKey:String = LocaleUtils.localeBinding("intellector.live_game.title");
        setTitle(titleKey, gameId);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, gameId);
        addComponent(label);
    }
}
