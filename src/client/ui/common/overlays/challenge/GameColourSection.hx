package client.ui.common.overlays.challenge;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.challenge.creation.CallerColorChoice;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import haxe.ui.containers.VBox;
import haxefolio.form.ChoiceRow;
import haxefolio.form.FieldGroup;

/**
    "Game and colour": rated or not, and the colour the creator plays. A rated game's colour is
    random, so the colour row is locked on Random while Rated is selected, the user's own choice
    coming back with Unrated. The game row is locked on Unrated for a guest (only players get rated
    games) and against a bot (bot games are never rated), the user's own choice coming back once
    neither holds.
**/
class GameColourSection extends VBox
{
    private final draft:ChallengeDraft;
    private final isGuest:Bool;
    private final onRatedChange:Void->Void;
    private final ratedRow:ChoiceRow<Bool>;
    private final colorRow:ChoiceRow<CallerColorChoice>;
    private final rows:FieldGroup;

    /** `onRatedChange` follows every change of `draft.rated` **/
    public function new(draft:ChallengeDraft, isGuest:Bool, onRatedChange:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM_SECTION);
        this.draft = draft;
        this.isGuest = isGuest;
        this.onRatedChange = onRatedChange;

        this.addComponent(new SectionHeading(phrase("section.game_colour")));

        ratedRow = new ChoiceRow<Bool>(phrase("field.game"), [
            {value: false, label: phrase("rated.unrated")},
            {value: true, label: phrase("rated.rated")}
        ], ChallengeDraftRules.effectiveRated(draft), onRatedSelected, null, ratedLocked(), ratedLockReason());
        ratedRow.percentWidth = StyleVars.CHALLENGE_OVERLAY_PAIR_FIELD_WIDTH_PERCENT;

        colorRow = new ChoiceRow<CallerColorChoice>(phrase("field.caller_color"), [
            {value: WHITE, label: phrase("caller_color.white")},
            {value: RANDOM, label: phrase("caller_color.random")},
            {value: BLACK, label: phrase("caller_color.black")}
        ], ChallengeDraftRules.effectiveCallerColor(draft), color -> draft.callerColor = color, null, ChallengeDraftRules.effectiveRated(draft));
        colorRow.percentWidth = StyleVars.CHALLENGE_OVERLAY_PAIR_FIELD_WIDTH_PERCENT;

        rows = new FieldGroup([ratedRow, colorRow], {expanded: Horizontal, collapsed: Vertical}, null, false, StyleVars.CHALLENGE_OVERLAY_GAME_COLOUR_GAP);
        this.addComponent(rows);
    }

    public function dispose():Void
    {
        ratedRow.dispose();
        colorRow.dispose();
        rows.dispose();
    }

    /** Follows a change of the challenge type, which may lock the game row **/
    public function onTypeChange():Void
    {
        ratedRow.setLocked(ratedLocked(), ratedLockReason());
        ratedRow.select(ChallengeDraftRules.effectiveRated(draft));
        showColor();
    }

    private function onRatedSelected(rated:Bool):Void
    {
        draft.rated = rated;
        showColor();
        onRatedChange();
    }

    private function showColor():Void
    {
        colorRow.setLocked(ChallengeDraftRules.effectiveRated(draft));
        colorRow.select(ChallengeDraftRules.effectiveCallerColor(draft));
    }

    private function ratedLocked():Bool
    {
        return isGuest || draft.type == BOT;
    }

    private function ratedLockReason():String
    {
        return draft.type == BOT ? phrase("hint.bot_rated") : phrase("hint.guest_rated");
    }
}
