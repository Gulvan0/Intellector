package client.ui.game;

import client.datatypes.game.GameParticipant;
import client.formatters.ClockFormatters;
import client.formatters.GameFormatters;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;

using client.ui.ComponentExtension;

/** A player above or below the board: presence, nickname, rating and clock **/
class PlayerBar extends HBox
{
    private static inline final LOW_TIME_MS:Float = 60 * 1000;

    private final presenceDot:Box;
    private final nicknameLabel:Label;
    private final ratingLabel:Label;
    private final clockLabel:Label;
    private var participant:Null<GameParticipant> = null;

    /** `onNicknameClicked`: called with the participant whose nickname was clicked **/
    public function new(onNicknameClicked:GameParticipant->Void)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_PLAYER_BAR);

        presenceDot = createPresenceDot();
        addComponent(presenceDot);

        nicknameLabel = new Label();
        nicknameLabel.addClass(StyleClass.GAME_NICKNAME);
        nicknameLabel.verticalAlign = "center";
        nicknameLabel.onClick = _ -> {
            if (participant != null)
                onNicknameClicked(participant);
        };
        addComponent(nicknameLabel);

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

    public function setParticipant(participant:GameParticipant):Void
    {
        this.participant = participant;
        nicknameLabel.text = participant.nickname;
        nicknameLabel.setClass(StyleClass.GAME_NICKNAME_LINK, isPlayer(participant));
        ratingLabel.text = GameFormatters.rating(participant.rating);
        ratingLabel.hidden = participant.rating == null;
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
        return !StringTools.startsWith(participant.ref, "_") && !StringTools.startsWith(participant.ref, "+");
    }
}
