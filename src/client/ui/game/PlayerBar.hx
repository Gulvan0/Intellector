package client.ui.game;

import client.datatypes.game.GameParticipant;
import client.formatters.ClockFormatters;
import client.formatters.GameFormatters;
import client.ui.common.WatchEye;
import client.utils.PagePaths;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;
import haxefolio.PageLink;

using client.ui.ComponentExtension;

/** A player above or below the board: presence, nickname (with the eye while watched), rating and clock **/
class PlayerBar extends HBox
{
    private static inline final LOW_TIME_MS:Float = 60 * 1000;

    private final presenceDot:Box;
    private final nicknameLabel:Label;
    private final nicknameLink:PageLink;
    private final watchEye:WatchEye;
    private final ratingLabel:Label;
    private final clockLabel:Label;
    private var ratingShown:Bool = true;
    private var hasRating:Bool = false;

    public function new()
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_PLAYER_BAR);

        presenceDot = createPresenceDot();
        addComponent(presenceDot);

        nicknameLabel = new Label();
        nicknameLabel.addClass(StyleClass.GAME_NICKNAME);
        nicknameLabel.verticalAlign = "center";
        nicknameLink = PageLink.attach(nicknameLabel, null);
        watchEye = new WatchEye();
        addComponent(nicknameGroup(nicknameLabel, watchEye));

        ratingLabel = new Label();
        ratingLabel.addClass(StyleClass.GAME_RATING);
        ratingLabel.verticalAlign = "center";
        addComponent(ratingLabel);

        var spacer:Box = new Box();
        spacer.percentWidth = 100;
        addComponent(spacer);

        clockLabel = new Label();
        clockLabel.addClass(StyleClass.GAME_CLOCK);
        clockLabel.verticalAlign = "center";
        addComponent(clockLabel);
    }

    /** A dot telling, in colour and tooltip, whether the player has the game open **/
    public static function createPresenceDot():Box
    {
        var dot:Box = new Box();
        dot.addClass(StyleClass.GAME_PRESENCE_DOT);
        dot.verticalAlign = "center";
        setPresence(dot, false);
        return dot;
    }

    public static function setPresence(dot:Component, present:Bool):Void
    {
        dot.setClass(StyleClass.GAME_PRESENCE_DOT_ON, present);
        dot.tooltip = LocaleUtils.localeBinding(present ? "intellector.live_game.presence.online" : "intellector.live_game.presence.offline");
    }

    /** The nickname and the eye beside it, kept together **/
    public static function nicknameGroup(nicknameLabel:Label, watchEye:WatchEye):HBox
    {
        var group:HBox = new HBox();
        group.verticalAlign = "center";
        group.addClass(StyleClass.GAME_NICKNAME_GROUP);
        group.addComponent(nicknameLabel);
        group.addComponent(watchEye);
        return group;
    }

    /** `watchedLogin`: the watched player's, null while watching no one **/
    public function setParticipant(participant:GameParticipant, watchedLogin:Null<String>):Void
    {
        nicknameLabel.text = participant.nickname;
        nicknameLabel.setClass(StyleClass.GAME_NICKNAME_LINK, isPlayer(participant));
        nicknameLink.setPath(PagePaths.playerProfile(participant.ref));
        watchEye.setUser(participant.ref, participant.nickname, watchedLogin);
        ratingLabel.text = GameFormatters.rating(participant.rating);
        hasRating = participant.rating != null;
        ratingLabel.hidden = !ratingShown || !hasRating;
    }

    public function setWatchedLogin(watchedLogin:Null<String>):Void
    {
        watchEye.setWatchedLogin(watchedLogin);
    }

    /** Whether the rating is shown next to the nickname, where there's a rating at all **/
    public function setRatingShown(shown:Bool):Void
    {
        ratingShown = shown;
        ratingLabel.hidden = !ratingShown || !hasRating;
    }

    public function setPresent(present:Bool):Void
    {
        setPresence(presenceDot, present);
    }

    /** `remainingMs`: null hides the clock (a correspondence game) **/
    public function setClock(remainingMs:Null<Float>, running:Bool):Void
    {
        clockLabel.hidden = remainingMs == null;
        if (remainingMs == null)
            return;

        clockLabel.text = ClockFormatters.formatRemainingTime(remainingMs);
        clockLabel.setClass(StyleClass.GAME_CLOCK_RUNNING, running);
        clockLabel.setClass(StyleClass.GAME_CLOCK_LOW, remainingMs < LOW_TIME_MS);
    }

    /** Guests have no profile to open **/
    public static function isPlayer(participant:GameParticipant):Bool
    {
        return PagePaths.playerProfile(participant.ref) != null;
    }
}
