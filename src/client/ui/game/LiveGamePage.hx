package client.ui.game;

import haxe.ui.components.Label;
import haxefolio.LocaleUtils;
import haxefolio.PageBase;

class LiveGamePage extends PageBase
{
    /** The id of the game the open live game page shows, null while none is open **/
    public static var openGameId(default, null):Null<Int> = null;

    private final gameId:Int;

    public function new(gameId:Int)
    {
        super();
        this.gameId = gameId;
    }

    private override function init():Void
    {
        openGameId = gameId;

        var titleKey:String = LocaleUtils.localeBinding("intellector.live_game.title");
        setTitle(titleKey, gameId);

        var label:Label = new Label();
        label.text = LocaleUtils.resolveText(titleKey, gameId);
        addComponent(label);
    }

    private override function onClose():Void
    {
        if (openGameId == gameId)
            openGameId = null;
    }
}
