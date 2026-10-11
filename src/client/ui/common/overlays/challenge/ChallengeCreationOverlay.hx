package client.ui.common.overlays.challenge;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.storage.ChallengeDraftStorage;
import client.datatypes.challenge.creation.ChallengeCreationOutcome;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.challenge.creation.ChallengeType;
import haxefolio.HaxeFolioApp;
import haxefolio.overlay.OverlayContent;
import haxefolio.structure.ActionBar;
import haxefolio.structure.ActionButton;

/**
    Creating a challenge: the form, and a footer whose primary action names what it does for the
    selected type. The primary action is disabled while the form is invalid or a request is in
    flight; the overlay stays open until the challenge exists, and remembers what it was created
    with for the next time.
**/
class ChallengeCreationOverlay
{
    /**
        `ownUserRef`: the current user's. `create` sends the request and reports how it ended; any
        notice about it is its own business. `initialType` overrides the remembered type.
    **/
    public static function present(isGuest:Bool, ownUserRef:Null<String>, create:ChallengeParams->(ChallengeCreationOutcome->Void)->Void, ?initialType:ChallengeType):Void
    {
        HaxeFolioApp.present("challenge", build.bind(isGuest, ownUserRef, create, initialType), null, {
            geometry: {
                dialogWidth: StyleVars.CHALLENGE_OVERLAY_WIDTH,
                dialogHeight: StyleVars.CHALLENGE_OVERLAY_HEIGHT,
                headerHeight: StyleVars.CHALLENGE_OVERLAY_HEADER_HEIGHT,
                actionBarHeight: StyleVars.CHALLENGE_OVERLAY_FOOTER_HEIGHT
            }
        });
    }

    private static function build(isGuest:Bool, ownUserRef:Null<String>, create:ChallengeParams->(ChallengeCreationOutcome->Void)->Void, initialType:Null<ChallengeType>, dismiss:Void->Void):OverlayContent
    {
        var form:Null<ChallengeCreationForm> = null;
        var submitButton:Null<ActionButton> = null;
        var busy:Bool = false;
        var dismissed:Bool = false;

        function refresh():Void
        {
            if (form == null || submitButton == null)
                return;

            submitButton.text = submitLabel(form.draft.type);
            submitButton.enabled = !busy && form.params() != null;
        }

        function onOutcome(outcome:ChallengeCreationOutcome):Void
        {
            busy = false;

            switch outcome
            {
                case Created | GameStarted:
                    ChallengeDraftStorage.save(form.draft);
                    if (!dismissed)
                        dismiss();
                case CalleeNotFound:
                    form.markCalleeNotFound();
                case Failed:
            }

            refresh();
        }

        function submit():Void
        {
            var params:Null<ChallengeParams> = form.params();

            if (busy || params == null)
                return;

            if (params.target.match(Bot)) // no bot to play yet
                return;

            busy = true;
            refresh();
            create(params, onOutcome);
        }

        var draft:ChallengeDraft = ChallengeDraftStorage.read();
        if (initialType != null)
            draft.type = initialType;
        ChallengeDraftRules.normalize(draft, isGuest);

        form = new ChallengeCreationForm(draft, isGuest, ownUserRef, refresh);

        var cancelButton:ActionButton = new ActionButton(phrase("cancel"), dismiss, false, null, StyleVars.CHALLENGE_OVERLAY_CANCEL_WIDTH_PERCENT);
        submitButton = new ActionButton(submitLabel(form.draft.type), submit, true);
        refresh();

        return {
            regions: [
                Header(phrase("title")),
                Scroll(form),
                Actions(new ActionBar([cancelButton, submitButton]))
            ],
            onDismissed: () -> {
                dismissed = true;
                form.dispose();
            }
        };
    }

    private static function submitLabel(type:ChallengeType):String
    {
        return phrase('submit.$type');
    }
}
