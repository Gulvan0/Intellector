package client.ui.common.overlays.challenge;

import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.datatypes.challenge.creation.ChallengeParams;
import haxe.ui.containers.VBox;

/**
    The challenge creation overlay's scrolling content: its four sections over one draft, which
    they edit in place. `onEdit` follows every edit, for the host to re-check `params()`.
**/
class ChallengeCreationForm extends VBox
{
    public final draft:ChallengeDraft;

    private final opponent:OpponentSection;
    private final timeControl:TimeControlSection;
    private final gameColour:GameColourSection;
    private final position:PositionSection;
    private final ownUserRef:Null<String>;
    private final onEdit:Void->Void;

    /** `ownUserRef`: the current user's, never a valid opponent **/
    public function new(draft:ChallengeDraft, isGuest:Bool, ownUserRef:Null<String>, onEdit:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM);
        this.draft = draft;
        this.ownUserRef = ownUserRef;
        this.onEdit = onEdit;

        opponent = new OpponentSection(draft, ownUserRef, onEdit);
        timeControl = new TimeControlSection(draft, onEdit);
        gameColour = new GameColourSection(draft, isGuest, onRatedChange);
        position = new PositionSection(draft, onEdit);

        this.addComponent(opponent);
        this.addComponent(timeControl);
        this.addComponent(gameColour);
        this.addComponent(position);
    }

    /**
        The challenge the form describes, or null while anything it needs is invalid: the draft, or
        input the draft doesn't hold (text a field couldn't read, an opponent the server didn't know)
    **/
    public function params():Null<ChallengeParams>
    {
        if (!opponent.isValid() || !timeControl.isValid() || !position.isValid())
            return null;

        return ChallengeDraftRules.params(draft, ownUserRef);
    }

    /** The server knows no one by the opponent's field's current value **/
    public function markCalleeNotFound():Void
    {
        opponent.markCalleeNotFound();
    }

    public function dispose():Void
    {
        opponent.dispose();
        timeControl.dispose();
        gameColour.dispose();
        position.dispose();
    }

    private function onRatedChange():Void
    {
        position.onRatedChange();
        onEdit();
    }
}
