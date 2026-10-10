package client;

import client.datatypes.StartedGame;
import haxefolio.HaxeFolioApp;
import haxefolio.LocaleUtils;
import haxefolio.browser.Blinker;
import js.Browser;
import js.html.Event;

/**
    Opens a game started by someone accepting the user's challenge in one of the browser's tabs: the
    focused one at once, otherwise the first one the user focuses, every tab blinking until then.
**/
class GameRedirect
{
    private static inline final BLINK_FAVICON:String = "assets/favicons/notification.png";

    private static var onClaimed:StartedGame->Void;
    private static var pendingGame:Null<StartedGame> = null;
    private static var blinker:Null<Blinker> = null;

    /** `onClaimed` opens the game in this tab **/
    public static function init(onClaimed:StartedGame->Void):Void
    {
        GameRedirect.onClaimed = onClaimed;

        Browser.window.addEventListener("focus", onFocusMaybeGained);
        Browser.document.addEventListener("visibilitychange", onFocusMaybeGained);
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.REDIRECTED_GAME_ID, onExternalClaim);
    }

    /** `game` has started; ignored if some tab has already opened it **/
    public static function request(game:StartedGame):Void
    {
        if (game.id <= readRedirectedGameId())
            return;

        if (Browser.document.hasFocus())
        {
            claim(game);
            return;
        }

        pendingGame = game;
        startBlinking();
    }

    private static function onFocusMaybeGained(_:Event):Void
    {
        var game:Null<StartedGame> = pendingGame;
        if (game == null || !Browser.document.hasFocus())
            return;

        dropPending();

        if (game.id > readRedirectedGameId())
            claim(game);
    }

    private static function onExternalClaim(serializedGameId:Null<String>):Void
    {
        if (pendingGame != null && pendingGame.id <= parseGameId(serializedGameId))
            dropPending();
    }

    private static function claim(game:StartedGame):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.REDIRECTED_GAME_ID, Std.string(game.id));
        onClaimed(game);
    }

    private static function dropPending():Void
    {
        pendingGame = null;

        if (blinker != null)
            blinker.stop();
    }

    private static function startBlinking():Void
    {
        if (blinker != null && blinker.isActive)
            return;

        var title:String = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.browser_tab.game_started"));
        blinker = new Blinker(title, BLINK_FAVICON);
        blinker.start();
    }

    private static function readRedirectedGameId():Int
    {
        return parseGameId(HaxeFolioApp.valueStorage.read(LocalStorageKey.REDIRECTED_GAME_ID));
    }

    private static function parseGameId(serializedGameId:Null<String>):Int
    {
        return serializedGameId != null ? (Std.parseInt(serializedGameId) ?? 0) : 0;
    }
}
