package client.ui.game;

import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxefolio.PageLink;

using client.ui.ComponentExtension;

typedef GameActionHandlers =
{
    onFlip:Void->Void,
    onDraw:Void->Void,
    onTakeback:Void->Void,
    onResign:Void->Void,
    onAddTime:Void->Void,
    onShare:Void->Void,
    onPlayFromHere:Void->Void,
    onRematch:Void->Void
}

/** What can be done with the game: two buttons a row while wide, a single icon row while compact **/
class ActionsCard extends VBox
{
    private final flipButton:Button;
    private final drawButton:Button;
    private final takebackButton:Button;
    private final resignButton:Button;
    private final addTimeButton:Button;
    private final analyzeButton:Button;
    private final analyzeLink:PageLink;
    private final shareButton:Button;
    private final playFromHereButton:Button;
    private final rematchButton:Button;

    private var shownButtons:Array<Button> = [];
    private var compact:Bool = false;
    private var drawOutgoing:Bool = false;
    private var takebackOutgoing:Bool = false;
    private var resignIsAbort:Bool = false;

    public function new(handlers:GameActionHandlers)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.GAME_ACTIONS_CARD);

        flipButton = GameButtons.action("flip", "intellector.live_game.action.flip", handlers.onFlip);
        drawButton = GameButtons.action("draw", "intellector.live_game.action.offer_draw", handlers.onDraw);
        takebackButton = GameButtons.action("takeback", "intellector.live_game.action.takeback", handlers.onTakeback);
        resignButton = GameButtons.action("resign", "intellector.live_game.action.resign", handlers.onResign);
        addTimeButton = GameButtons.action("add_time", "intellector.live_game.action.add_time", handlers.onAddTime);
        analyzeButton = GameButtons.action("analyze", "intellector.live_game.action.analyze", null);
        analyzeLink = PageLink.attach(analyzeButton, null);
        shareButton = GameButtons.action("share", "intellector.live_game.action.share", handlers.onShare);
        playFromHereButton = GameButtons.action("play_from_here", "intellector.live_game.action.play_from_here", handlers.onPlayFromHere);
        rematchButton = GameButtons.action("rematch", "intellector.live_game.action.rematch", handlers.onRematch);
    }

    /** The set of a player of an ongoing game; Add time only in a timed one **/
    public function showPlayerActions(timed:Bool):Void
    {
        var buttons:Array<Button> = [flipButton, drawButton, takebackButton, resignButton];
        if (timed)
            buttons.push(addTimeButton);
        showButtons(buttons);
    }

    /** The set of a spectator, or of anyone once the game is over **/
    public function showViewerActions(withRematch:Bool):Void
    {
        var buttons:Array<Button> = [flipButton, analyzeButton, shareButton, playFromHereButton];
        if (withRematch)
            buttons.push(rematchButton);
        showButtons(buttons);
    }

    /** Where Analyze leads; null while there is nowhere yet **/
    public function setAnalysisPath(path:Null<String>):Void
    {
        analyzeLink.setPath(path);
    }

    /** `outgoing`: the user's own offer is pending, so the button cancels it **/
    public function setDrawState(outgoing:Bool, enabled:Bool):Void
    {
        drawOutgoing = outgoing;
        drawButton.disabled = !enabled;
        refreshCaptions();
    }

    public function setTakebackState(outgoing:Bool, enabled:Bool):Void
    {
        takebackOutgoing = outgoing;
        takebackButton.disabled = !enabled;
        refreshCaptions();
    }

    /** Until both sides have moved, leaving aborts the game instead of losing it **/
    public function setResignIsAbort(abort:Bool):Void
    {
        resignIsAbort = abort;
        refreshCaptions();
    }

    /** Compact: one row, icons only **/
    public function setCompact(compact:Bool):Void
    {
        this.compact = compact;
        showButtons(shownButtons);
    }

    private function showButtons(buttons:Array<Button>):Void
    {
        for (button in shownButtons)
            if (button.parentComponent != null)
                button.parentComponent.removeComponent(button, false);
        removeAllComponents();
        shownButtons = buttons;

        var rowSize:Int = compact ? buttons.length : 2;
        var i:Int = 0;
        while (i < buttons.length)
        {
            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.addClass(StyleClass.GAME_ACTIONS_ROW);
            addComponent(row);

            var rowButtons:Array<Button> = buttons.slice(i, i + rowSize);
            for (button in rowButtons)
            {
                button.percentWidth = 100 / rowButtons.length;
                row.addComponent(button);
            }
            i += rowSize;
        }

        refreshCaptions();
    }

    private function refreshCaptions():Void
    {
        var showCaption:Bool = !compact;
        GameButtons.setCaption(flipButton, "intellector.live_game.action.flip", showCaption);
        GameButtons.setCaption(drawButton, drawOutgoing ? "intellector.live_game.action.cancel_draw" : "intellector.live_game.action.offer_draw", showCaption);
        GameButtons.setCaption(takebackButton, takebackOutgoing ? "intellector.live_game.action.cancel_takeback" : "intellector.live_game.action.takeback", showCaption);
        GameButtons.setCaption(resignButton, resignIsAbort ? "intellector.live_game.action.abort" : "intellector.live_game.action.resign", showCaption);
        GameButtons.setCaption(addTimeButton, "intellector.live_game.action.add_time", showCaption);
        GameButtons.setCaption(analyzeButton, "intellector.live_game.action.analyze", showCaption);
        GameButtons.setCaption(shareButton, "intellector.live_game.action.share", showCaption);
        GameButtons.setCaption(playFromHereButton, "intellector.live_game.action.play_from_here", showCaption);
        GameButtons.setCaption(rematchButton, "intellector.live_game.action.rematch", showCaption);

        drawButton.icon = GameButtons.icon(drawOutgoing ? "cancel_accent" : "draw");
        takebackButton.icon = GameButtons.icon(takebackOutgoing ? "cancel_accent" : "takeback");
        drawButton.setClass(StyleClass.GAME_BUTTON_ON, drawOutgoing);
        takebackButton.setClass(StyleClass.GAME_BUTTON_ON, takebackOutgoing);
    }
}
