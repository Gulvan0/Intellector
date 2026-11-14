package client.ui.games.flow;

import client.datatypes.player.FoundPlayer;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.logic.watch.WatchedNicknameParsing;
import client.ui.common.board.BoardPreview;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.form.TextInputField;
import intellectorboard.position.Position;
import intellectorboard.primitives.piece.PieceColor;

using StringTools;

/** The steps that are a text field: a user's login, a guest's number, a SIP, a whole number **/
class TextSteps
{
    private static inline final FIND_PLAYER_GLYPH:String = '<circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/>';
    private static inline final GUEST_PREFIX_WIDTH:Int = 64;
    private static inline final SIP_BOARD_WIDTH:Float = 240;
    private static inline final BODY_WIDTH:Float = 300;

    /** `overOverlay`: the player search opens over the sheet the step is in **/
    public static function user(title:Void->String, initial:Null<String>, back:Null<Void->Void>, overOverlay:Bool, onValue:String->Void):FlowStep
    {
        var field:Null<TextInputField> = null;
        var confirm:Void->Void = () -> {
            var login:Null<String> = WatchedNicknameParsing.login(field.currentText);
            if (login != null)
                onValue(login);
        };
        var footer:StepFooter = new StepFooter(confirm);

        var refresh:Void->Void = () -> {
            var text:String = field.currentText.trim();
            var login:Null<String> = WatchedNicknameParsing.login(text);
            var invalid:Bool = text != "" && login == null;
            field.invalid = invalid;
            field.hintState = invalid ? Error : Normal;
            field.hint = LocaleUtils.localeBinding(invalid ? "intellector.games.step.user.invalid" : "intellector.games.step.user.hint");
            footer.enabled = login != null;
        };

        field = new TextInputField(LocaleUtils.localeBinding("intellector.games.step.user.label"), _ -> refresh(), confirm);
        field.currentText = initial ?? "";
        field.setAction(FIND_PLAYER_GLYPH, LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.games.step.user.find")), () -> {
            PlayerSearchOverlay.present(title(), false, (player:FoundPlayer) -> {
                field.currentText = player.login;
                refresh();
            }, field.currentText, overOverlay);
        });
        refresh();

        return new FlowStep(title, body(field), footer, back, () -> field.currentText != "", field.focus);
    }

    public static function guest(title:Void->String, initial:Null<Int>, back:Null<Void->Void>, onValue:Int->Void):FlowStep
    {
        return number(title, LocaleUtils.localeBinding("intellector.games.step.guest.label"), "intellector.games.step.guest.hint", 1, initial, back, onValue, LocaleUtils.localeBinding("intellector.games.step.guest.prefix"));
    }

    /** A whole number from `min` on **/
    public static function wholeNumber(title:Void->String, label:String, min:Int, initial:Null<Int>, back:Null<Void->Void>, onValue:Int->Void, ?lowerBound:Int):FlowStep
    {
        var hintKey:String = min == 0 ? "intellector.games.step.number.hint_from_zero" : "intellector.games.step.number.hint";
        return number(title, label, hintKey, min, initial, back, onValue, null, lowerBound);
    }

    /** `lowerBound`: an upper bound's lower one, which it must exceed **/
    private static function number(title:Void->String, label:String, hintKey:String, min:Int, initial:Null<Int>, back:Null<Void->Void>, onValue:Int->Void, ?prefix:String, ?lowerBound:Int):FlowStep
    {
        var field:Null<TextInputField> = null;
        var value:Null<Int> = null;
        var confirm:Void->Void = () -> {
            if (value != null)
                onValue(value);
        };
        var footer:StepFooter = new StepFooter(confirm);

        var refresh:Void->Void = () -> {
            var text:String = field.currentText.trim();
            var parsed:Null<Int> = ~/^-?[0-9]{1,9}$/.match(text) ? Std.parseInt(text) : null;
            var errorKey:Null<String> = null;
            if (text != "" && parsed == null)
                errorKey = "intellector.games.step.number.not_a_number";
            else if (parsed != null && parsed < min)
                errorKey = min == 0 ? "intellector.games.step.number.negative" : "intellector.games.step.number.below_one";
            else if (parsed != null && lowerBound != null && parsed <= lowerBound)
                errorKey = "intellector.games.step.above_lower_bound";

            value = errorKey == null ? parsed : null;
            field.invalid = errorKey != null;
            field.hintState = errorKey != null ? Error : Normal;
            field.hint = errorKey != null ? LocaleUtils.localeBinding(errorKey, Std.string(lowerBound)) : LocaleUtils.localeBinding(hintKey);
            footer.enabled = value != null;
        };

        field = new TextInputField(label, _ -> refresh(), confirm);
        field.setNumericKeyboard(true);
        if (prefix != null)
            field.setPrefix(prefix, GUEST_PREFIX_WIDTH);
        field.currentText = initial != null ? Std.string(initial) : "";
        refresh();

        return new FlowStep(title, body(field), footer, back, () -> field.currentText != "", field.focus);
    }

    /** A SIP, with the position it describes beneath **/
    public static function sip(title:Void->String, initial:Null<String>, back:Null<Void->Void>, onValue:String->Void):FlowStep
    {
        var field:Null<TextInputField> = null;
        var parsed:Null<Position> = null;
        var confirm:Void->Void = () -> {
            if (parsed != null)
                onValue(field.currentText.trim());
        };
        var footer:StepFooter = new StepFooter(confirm);

        var inset:Box = new Box();
        inset.percentWidth = 100;
        inset.height = BoardPreview.heightFor(SIP_BOARD_WIDTH) + 2 * StyleVars.IMPORT_POSITION_INSET_PADDING;
        inset.addClass(StyleClass.IMPORT_POSITION_INSET);

        var board:BoardPreview = new BoardPreview(Position.defaultStarting(), PieceColor.White, SIP_BOARD_WIDTH);
        board.horizontalAlign = "center";
        inset.addComponent(board);

        var noPreview:Label = new Label();
        noPreview.text = LocaleUtils.localeBinding("intellector.games.step.sip.no_preview");
        noPreview.addClass(StyleClass.GAMES_RESULTS_STATE_TEXT);
        noPreview.horizontalAlign = "center";
        noPreview.verticalAlign = "center";
        inset.addComponent(noPreview);

        var refresh:Void->Void = () -> {
            var text:String = field.currentText.trim();
            parsed = text == "" ? null : ChallengeDraftRules.parseSip(text);
            var invalid:Bool = text != "" && parsed == null;
            field.invalid = invalid;
            field.hintState = invalid ? Error : Normal;
            field.hint = LocaleUtils.localeBinding(invalid ? "intellector.games.step.sip.invalid" : "intellector.games.step.sip.hint");
            board.hidden = parsed == null;
            noPreview.hidden = parsed != null;
            if (parsed != null)
                board.setPosition(parsed);
            footer.enabled = parsed != null;
        };

        field = new TextInputField(LocaleUtils.localeBinding("intellector.games.step.sip.label"), _ -> refresh(), confirm);
        field.selectAllOnFocus = true;
        field.currentText = initial ?? "";
        refresh();

        var content:VBox = body(field);
        content.addComponent(inset);
        return new FlowStep(title, content, footer, back, () -> field.currentText != "", field.focus);
    }

    private static function body(field:TextInputField):VBox
    {
        var content:VBox = new VBox();
        content.addClass(StyleClass.GAMES_STEP_BODY);
        FlowLayout.size(content, BODY_WIDTH);
        field.percentWidth = 100;
        content.addComponent(field);
        return content;
    }
}
