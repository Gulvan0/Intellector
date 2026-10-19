package client.ui.common.overlays.playersearch;

import client.datatypes.player.FoundPlayer;
import client.formatters.PlayerSearchFormatters;
import client.ui.common.LoadStatus;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;

/*
    What the overlay's scrolling area shows: the found players' cards, a message for an empty query
    or no match, or the failure of the last search. The messages sit where they are centred in the
    dialog's results area; the sheet keeps that offset from its top, above the on-screen keyboard.
*/
class PlayerSearchResultList extends VBox
{
    private final onPicked:FoundPlayer->Void;

    private final rows:VBox;
    private final message:VBox;
    private final messageText:Label;
    private final messageHint:Label;
    private final loadStatus:LoadStatus;

    private var startShown:Bool = false;

    public function new(onPicked:FoundPlayer->Void)
    {
        super();
        this.onPicked = onPicked;
        percentWidth = 100;
        addClass(StyleClass.PLAYER_SEARCH_LIST);

        rows = new VBox();
        rows.percentWidth = 100;
        rows.addClass(StyleClass.PLAYER_SEARCH_ROWS);
        addComponent(rows);

        message = new VBox();
        message.percentWidth = 100;
        message.addClass(StyleClass.PLAYER_SEARCH_EMPTY);
        addComponent(message);

        messageText = new Label();
        messageText.horizontalAlign = "center";
        messageText.addClass(StyleClass.PLAYER_SEARCH_EMPTY_TEXT);
        message.addComponent(messageText);

        messageHint = new Label();
        messageHint.horizontalAlign = "center";
        messageHint.addClass(StyleClass.PLAYER_SEARCH_EMPTY_HINT);
        message.addComponent(messageHint);

        loadStatus = new LoadStatus();
        loadStatus.addClass(StyleClass.PLAYER_SEARCH_FAILURE);
        addComponent(loadStatus);

        showStart();
    }

    /** The prompt to start typing **/
    public function showStart():Void
    {
        showMessage(LocaleUtils.localeBinding("intellector.overlay.player_search.start"), LocaleUtils.localeBinding("intellector.overlay.player_search.start_hint"));
        startShown = true;
    }

    /** Keeps what is shown until the answer comes, except the prompt to start typing, which goes **/
    public function showPending():Void
    {
        if (startShown)
            showParts(false, false, false);
    }

    /** `query`: what the players were found by **/
    public function showPlayers(players:Array<FoundPlayer>, query:String):Void
    {
        if (players.length == 0)
        {
            showMessage(PlayerSearchFormatters.noMatch(query), LocaleUtils.localeBinding("intellector.overlay.player_search.none_hint"));
            return;
        }

        rows.removeAllComponents();
        for (player in players)
            rows.addComponent(new PlayerSearchRow(player, query, onPicked));
        showParts(true, false, false);
    }

    public function showRetrying():Void
    {
        loadStatus.showLoading();
        showParts(false, false, true);
    }

    /** `timedOut`: the server didn't answer in time, rather than answered with an error **/
    public function showFailure(timedOut:Bool, onRetry:Void->Void):Void
    {
        loadStatus.showFailure(timedOut, onRetry);
        showParts(false, false, true);
    }

    private function showMessage(text:String, hint:String):Void
    {
        messageText.text = text;
        messageHint.text = hint;
        showParts(false, true, false);
    }

    private function showParts(rowsShown:Bool, messageShown:Bool, statusShown:Bool):Void
    {
        startShown = false;
        rows.hidden = !rowsShown;
        message.hidden = !messageShown;
        loadStatus.hidden = !statusShown;

        if (!rowsShown)
            rows.removeAllComponents();
    }
}
