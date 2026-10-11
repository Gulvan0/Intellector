package client.ui.common.overlays.challenge;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import client.datatypes.challenge.creation.StartingPositionMode;
import client.ui.Assets;
import client.ui.common.board.BoardGeometry;
import client.ui.common.board.BoardSurface;
import haxe.ui.containers.Box;
import haxe.ui.containers.VBox;
import haxefolio.form.ChoiceRow;
import haxefolio.form.CommitTextField;
import haxefolio.form.FieldGroup;
import haxefolio.form.PreviewPane;
import haxefolio.form.plumbing.CommitResult;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;

/**
    "Starting position": Default or Custom, a custom one typed as SIP and applied explicitly, and a
    preview of the position in effect. The switch is locked on Default while the game is rated. The
    draft keeps the last applied custom position; `onEdit` follows every edit.
**/
class PositionSection extends VBox
{
    private final draft:ChallengeDraft;
    private final onEdit:Void->Void;
    private final modeRow:ChoiceRow<StartingPositionMode>;
    private final sipField:CommitTextField;
    private final board:BoardSurface;
    private final preview:PreviewPane;
    private final group:FieldGroup;
    private var rejected:Bool = false; // the field holds a SIP that failed to apply

    public function new(draft:ChallengeDraft, onEdit:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM_SECTION);
        this.draft = draft;
        this.onEdit = onEdit;

        modeRow = new ChoiceRow<StartingPositionMode>(null, [
            {value: DEFAULT, label: phrase("position.default")},
            {value: CUSTOM, label: phrase("position.custom")}
        ], ChallengeDraftRules.effectivePositionMode(draft), onModeSelected, null, draft.rated);
        modeRow.width = StyleVars.CHALLENGE_OVERLAY_POSITION_SWITCH_WIDTH;

        this.addComponent(new SectionHeading(phrase("section.position"), modeRow));

        sipField = new CommitTextField(
            null,
            Sip.DEFAULT_STARTING_POSITION_SIP,
            onSipEdited,
            applySip,
            phrase("apply"),
            phrase("hint.position.idle"),
            phrase("hint.position.applied"),
            ButtonAndEnter,
            true,
            phrase("hint.position.pending")
        );
        sipField.addClass(StyleClass.CHALLENGE_SIP_FIELD);

        var boardSlot:Box = new Box();
        boardSlot.width = StyleVars.CHALLENGE_OVERLAY_PREVIEW_BOARD_WIDTH;
        boardSlot.height = previewBoardHeight();

        var shown:Position = ChallengeDraftRules.startingPosition(draft);
        board = new BoardSurface(shown, White, NONE);
        boardSlot.addComponent(board);

        preview = new PreviewPane(
            StyleVars.CHALLENGE_OVERLAY_PREVIEW_BOARD_WIDTH,
            previewBoardHeight(),
            boardSlot,
            GroupedLocaleResolvers.turnColor(shown.turnColor),
            Assets.colorIcon(shown.turnColor)
        );
        preview.horizontalAlign = "center";

        // the group stretches its fields, so the preview is centred inside a full-width box
        var previewRow:Box = new Box();
        previewRow.addClass(StyleClass.CHALLENGE_PREVIEW_ROW);
        previewRow.addComponent(preview);

        group = new FieldGroup([sipField, previewRow]);
        this.addComponent(group);

        render();
    }

    /** Follows a change of whether the draft is rated, which forces the default position **/
    public function onRatedChange():Void
    {
        modeRow.setLocked(draft.rated);
        modeRow.select(ChallengeDraftRules.effectivePositionMode(draft));
        render();
    }

    /** Whether no SIP that failed to apply is pending, while the position is custom **/
    public function isValid():Bool
    {
        return ChallengeDraftRules.effectivePositionMode(draft) == DEFAULT || !rejected;
    }

    public function dispose():Void
    {
        modeRow.dispose();
        group.dispose();
    }

    private function onModeSelected(mode:StartingPositionMode):Void
    {
        draft.positionMode = mode;
        rejected = false;
        render();
        onEdit();
    }

    private function onSipEdited(_:String):Void
    {
        if (!rejected)
            return;

        rejected = false;
        onEdit();
    }

    private function applySip(text:String):CommitResult
    {
        var position:Null<Position> = ChallengeDraftRules.parseSip(text);

        if (position == null)
            return reject("error.invalid_sip");

        if (!position.isValidStarting())
            return reject("error.invalid_starting_position");

        rejected = false;
        draft.customSip = StringTools.trim(text);
        showPosition(ChallengeDraftRules.startingPosition(draft));
        onEdit();
        return Applied;
    }

    private function reject(errorKey:String):CommitResult
    {
        rejected = true;
        onEdit();
        return Rejected(phrase(errorKey));
    }

    private function render():Void
    {
        var custom:Bool = ChallengeDraftRules.effectivePositionMode(draft) == CUSTOM;

        sipField.enabled = custom;
        sipField.idleHint = custom ? phrase("hint.position.idle") : draft.rated ? phrase("hint.position.rated") : phrase("hint.position.default");
        sipField.currentText = custom ? draft.customSip ?? Sip.DEFAULT_STARTING_POSITION_SIP : Sip.DEFAULT_STARTING_POSITION_SIP;

        showPosition(ChallengeDraftRules.startingPosition(draft));
    }

    private function showPosition(position:Position):Void
    {
        board.setPosition(position, Replacement);
        preview.caption = GroupedLocaleResolvers.turnColor(position.turnColor);
        preview.captionIcon = Assets.colorIcon(position.turnColor);
    }

    private static function previewBoardHeight():Int
    {
        return Math.round(StyleVars.CHALLENGE_OVERLAY_PREVIEW_BOARD_WIDTH * BoardGeometry.GRID_HEIGHT / BoardGeometry.GRID_WIDTH);
    }
}
