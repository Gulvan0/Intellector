package client.ui.common.overlays.challenge;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.challenge.creation.CalleeInput;
import client.datatypes.challenge.creation.CalleeKind;
import client.logic.challenge.creation.CalleeParsing;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.datatypes.challenge.creation.ChallengeTarget;
import client.datatypes.challenge.creation.ChallengeType;
import client.datatypes.challenge.creation.OpenChallengeVisibility;
import client.datatypes.player.FoundPlayer;
import client.ui.common.overlays.playersearch.PlayerSearchOverlay;
import haxe.ui.components.Label;
import haxe.ui.containers.VBox;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.form.ChoiceRow;
import haxefolio.form.TextInputField;
import haxefolio.structure.SwapSlot;
import morestd.Detachable;

/**
    "Challenge type": the type, and below it a fixed-height slot with what that type needs - the
    opponent (a player's login or a guest's number) for Direct, the visibility for Open, a note for
    Against bot. Writes straight into the draft; `onEdit` follows every edit.
**/
class OpponentSection extends VBox
{
    private static inline final FIND_PLAYER_GLYPH:String = '<circle cx="7" cy="7" r="4.5"/><path d="M10.5 10.5L14 14"/>';

    private final draft:ChallengeDraft;
    private final ownUserRef:Null<String>;
    private final onEdit:Void->Void;
    private final typeRow:ChoiceRow<ChallengeType>;
    private final calleeKindRow:ChoiceRow<CalleeKind>;
    private final visibilityRow:ChoiceRow<OpenChallengeVisibility>;
    private final loginField:TextInputField;
    private final guestField:TextInputField;
    private final slot:SwapSlot<ChallengeType>;
    private final slotHeightBinding:Detachable;
    private var loginTouched:Bool = false;
    private var guestTouched:Bool = false;
    private var calleeNotFound:Null<String> = null; // the user ref the server didn't know

    public function new(draft:ChallengeDraft, ownUserRef:Null<String>, onEdit:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM_SECTION);
        this.draft = draft;
        this.ownUserRef = ownUserRef;
        this.onEdit = onEdit;

        this.addComponent(new SectionHeading(phrase("section.type")));

        typeRow = new ChoiceRow<ChallengeType>(null, [
            {value: DIRECT, label: phrase("type.direct")},
            {value: OPEN, label: phrase("type.open")},
            {value: BOT, label: phrase("type.bot")}
        ], draft.type, onTypeSelected);
        this.addComponent(typeRow);

        calleeKindRow = new ChoiceRow<CalleeKind>(null, [
            {value: PLAYER, label: phrase("callee_kind.player")},
            {value: GUEST, label: phrase("callee_kind.guest")}
        ], draft.calleeKind, onCalleeKindSelected);

        loginField = new TextInputField(phrase("field.login"), onLoginEdited);
        loginField.currentText = draft.calleeLogin;
        loginField.setAction(FIND_PLAYER_GLYPH, LocaleUtils.resolveText(phrase("find_player")), openPlayerSearch);

        guestField = new TextInputField(phrase("field.guest_number"), onGuestNumberEdited);
        guestField.currentText = draft.calleeGuestNumber;
        guestField.setPrefix(phrase("guest_prefix"), StyleVars.CHALLENGE_OVERLAY_GUEST_NUMBER_INPUT_PADDING_LEFT);
        guestField.setNumericKeyboard(true);
        guestField.addClass(StyleClass.CHALLENGE_GUEST_NUMBER_FIELD);

        var directBox:VBox = new VBox();
        directBox.addClass(StyleClass.CHALLENGE_DIRECT_SLOT);
        directBox.addComponent(calleeKindRow);
        directBox.addComponent(loginField);
        directBox.addComponent(guestField);

        visibilityRow = new ChoiceRow<OpenChallengeVisibility>(phrase("field.visibility"), [
            {value: PUBLIC, label: phrase("visibility.public")},
            {value: LINK_ONLY, label: phrase("visibility.link_only")}
        ], draft.visibility, visibility -> draft.visibility = visibility);

        var botNote:Label = new Label();
        botNote.text = phrase("bot_note");
        botNote.addClass(StyleClass.CHALLENGE_SLOT_NOTE);

        slot = new SwapSlot([DIRECT => directBox, OPEN => visibilityRow, BOT => botNote], draft.type, StyleVars.CHALLENGE_OVERLAY_TYPE_SLOT_HEIGHT.resolve(false));
        slot.addClass(StyleClass.CHALLENGE_TYPE_SLOT);
        this.addComponent(slot);

        slotHeightBinding = ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_TYPE_SLOT_HEIGHT, height -> slot.height = height);

        showCalleeKind();
        render();
    }

    /** Whether the opponent named isn't one the server reported unknown **/
    public function isValid():Bool
    {
        var target:Null<ChallengeTarget> = ChallengeDraftRules.target(draft, ownUserRef);
        return calleeNotFound == null || target == null || target.calleeRef() != calleeNotFound;
    }

    /** The server knows no one by the opponent's field's current value **/
    public function markCalleeNotFound():Void
    {
        switch ChallengeDraftRules.calleeInput(draft, ownUserRef)
        {
            case Valid(target):
                calleeNotFound = target.calleeRef();
                render();
            default:
        }
    }

    public function dispose():Void
    {
        typeRow.dispose();
        calleeKindRow.dispose();
        visibilityRow.dispose();
        loginField.dispose();
        guestField.dispose();
        slotHeightBinding.detach();
    }

    private function onTypeSelected(type:ChallengeType):Void
    {
        draft.type = type;
        slot.active = type;
        onEdit();
    }

    private function onCalleeKindSelected(kind:CalleeKind):Void
    {
        draft.calleeKind = kind;
        showCalleeKind();
        render();
        onEdit();
    }

    private function onLoginEdited(value:String):Void
    {
        draft.calleeLogin = value;
        loginTouched = true;
        render();
        onEdit();
    }

    private function openPlayerSearch():Void
    {
        PlayerSearchOverlay.present(phrase("choose_opponent"), true, onOpponentPicked, loginField.currentText, true);
    }

    private function onOpponentPicked(player:FoundPlayer):Void
    {
        loginField.currentText = player.login;
        onLoginEdited(player.login);
    }

    private function onGuestNumberEdited(value:String):Void
    {
        draft.calleeGuestNumber = value;
        guestTouched = true;
        render();
        onEdit();
    }

    private function showCalleeKind():Void
    {
        loginField.hidden = draft.calleeKind != PLAYER;
        guestField.hidden = draft.calleeKind != GUEST;
    }

    private function render():Void
    {
        renderField(loginField, CalleeParsing.parseLogin(draft.calleeLogin, ownUserRef), loginTouched, "enter_login");
        renderField(guestField, CalleeParsing.parseGuestNumber(draft.calleeGuestNumber, ownUserRef), guestTouched, "enter_number");
    }

    private function renderField(field:TextInputField, input:CalleeInput, touched:Bool, emptyErrorSlug:String):Void
    {
        var errorSlug:Null<String> = null;
        var fineHint:Null<String> = null;

        switch input
        {
            case Empty:
                if (touched)
                    errorSlug = emptyErrorSlug;
                else
                    fineHint = phrase("hint.required");
            case Invalid(slug):
                errorSlug = slug;
            case Valid(target):
                if (target.calleeRef() == calleeNotFound)
                    errorSlug = target.match(Guest(_)) ? "guest_not_found" : "player_not_found";
                else if (field == loginField)
                    fineHint = guestName(target);
        }

        field.invalid = errorSlug != null;
        field.hintState = errorSlug != null ? Error : Normal;
        field.hint = errorSlug != null ? phrase('error.$errorSlug') : fineHint;
    }

    // what a guest typed into the login field reads as, so it's clear who gets called
    private function guestName(target:ChallengeTarget):Null<String>
    {
        return switch target {
            case Guest(guestId): LocaleUtils.localeBinding("intellector.common.player.guest_name", Std.string(guestId));
            default: null;
        }
    }
}
