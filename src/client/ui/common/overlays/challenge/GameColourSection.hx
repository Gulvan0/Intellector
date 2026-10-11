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
    coming back with Unrated. A guest's game row is locked on Unrated: only players get rated games.
**/
class GameColourSection extends VBox
{
    private final draft:ChallengeDraft;
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
        this.onRatedChange = onRatedChange;

        this.addComponent(new SectionHeading(phrase("section.game_colour")));

        ratedRow = new ChoiceRow<Bool>(phrase("field.game"), [
            {value: false, label: phrase("rated.unrated")},
            {value: true, label: phrase("rated.rated")}
        ], draft.rated, onRatedSelected, null, isGuest, phrase("hint.guest_rated"));
        ratedRow.percentWidth = StyleVars.CHALLENGE_OVERLAY_PAIR_FIELD_WIDTH_PERCENT;

        colorRow = new ChoiceRow<CallerColorChoice>(phrase("field.caller_color"), [
            {value: WHITE, label: phrase("caller_color.white")},
            {value: RANDOM, label: phrase("caller_color.random")},
            {value: BLACK, label: phrase("caller_color.black")}
        ], ChallengeDraftRules.effectiveCallerColor(draft), color -> draft.callerColor = color, null, draft.rated);
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

    private function onRatedSelected(rated:Bool):Void
    {
        draft.rated = rated;
        colorRow.setLocked(rated);
        colorRow.select(ChallengeDraftRules.effectiveCallerColor(draft));
        onRatedChange();
    }
}
