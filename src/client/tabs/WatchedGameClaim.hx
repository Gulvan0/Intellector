package client.tabs;

import client.datatypes.game.OngoingGame;
import client.storage.LocalStorageKey;
import haxefolio.HaxeFolioApp;
import js.Browser;
import js.html.Event;

/**
    Hands a game the watched player has started to one of the browser's tabs: the focused one at
    once, otherwise the first one the user focuses while the game is still going. The tabs it isn't
    handed to, or not yet, are told so.
**/
class WatchedGameClaim
{
    private static var onClaimed:OngoingGame->Void;
    private static var onPassed:OngoingGame->Void;
    private static var pendingGame:Null<OngoingGame> = null;

    /** `onClaimed`: the game is this tab's to open. `onPassed`: it isn't, at least for now **/
    public static function init(onClaimed:OngoingGame->Void, onPassed:OngoingGame->Void):Void
    {
        WatchedGameClaim.onClaimed = onClaimed;
        WatchedGameClaim.onPassed = onPassed;

        Browser.window.addEventListener("focus", onFocusMaybeGained);
        Browser.document.addEventListener("visibilitychange", onFocusMaybeGained);
        HaxeFolioApp.valueStorage.addExternalChangeHandler(LocalStorageKey.CLAIMED_WATCHED_GAME_ID, onExternalClaim);
    }

    public static function request(game:OngoingGame):Void
    {
        if (game.id <= readClaimedGameId())
        {
            onPassed(game);
            return;
        }

        if (Browser.document.hasFocus())
        {
            claim(game);
            return;
        }

        pendingGame = game;
        onPassed(game);
    }

    /** Game `gameId` has ended: no tab claims it any more **/
    public static function cancel(gameId:Int):Void
    {
        if (pendingGame != null && pendingGame.id == gameId)
            pendingGame = null;
    }

    private static function onFocusMaybeGained(_:Event):Void
    {
        var game:Null<OngoingGame> = pendingGame;
        if (game == null || !Browser.document.hasFocus())
            return;

        pendingGame = null;

        if (game.id > readClaimedGameId())
            claim(game);
    }

    private static function onExternalClaim(serializedGameId:Null<String>):Void
    {
        if (pendingGame != null && pendingGame.id <= parseGameId(serializedGameId))
            pendingGame = null;
    }

    private static function claim(game:OngoingGame):Void
    {
        HaxeFolioApp.valueStorage.write(LocalStorageKey.CLAIMED_WATCHED_GAME_ID, Std.string(game.id));
        onClaimed(game);
    }

    private static function readClaimedGameId():Int
    {
        return parseGameId(HaxeFolioApp.valueStorage.read(LocalStorageKey.CLAIMED_WATCHED_GAME_ID));
    }

    private static function parseGameId(serializedGameId:Null<String>):Int
    {
        return serializedGameId != null ? (Std.parseInt(serializedGameId) ?? 0) : 0;
    }
}
