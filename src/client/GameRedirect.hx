package client;

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

    private static var onClaimed:Int->Void;
    private static var pendingGameId:Null<Int> = null;
    private static var blinker:Null<Blinker> = null;

    /** `onClaimed` opens the game in this tab **/
    public static function init(onClaimed:Int->Void):Void
    {
        GameRedirect.onClaimed = onClaimed;

        Browser.window.addEventListener("focus", onFocusMaybeGained);
        Browser.document.addEventListener("visibilitychange", onFocusMaybeGained);
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.REDIRECTED_GAME_ID, onExternalClaim);
    }

    /** Game `gameId` has started; ignored if some tab has already opened it **/
    public static function request(gameId:Int):Void
    {
        if (gameId <= readRedirectedGameId())
            return;

        if (Browser.document.hasFocus())
        {
            claim(gameId);
            return;
        }

        pendingGameId = gameId;
        startBlinking();
    }

    private static function onFocusMaybeGained(_:Event):Void
    {
        var gameId:Null<Int> = pendingGameId;
        if (gameId == null || !Browser.document.hasFocus())
            return;

        dropPending();

        if (gameId > readRedirectedGameId())
            claim(gameId);
    }

    private static function onExternalClaim(serializedGameId:Null<String>):Void
    {
        if (pendingGameId != null && pendingGameId <= parseGameId(serializedGameId))
            dropPending();
    }

    private static function claim(gameId:Int):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.REDIRECTED_GAME_ID, Std.string(gameId));
        onClaimed(gameId);
    }

    private static function dropPending():Void
    {
        pendingGameId = null;

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
