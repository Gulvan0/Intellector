package client.ui.common.overlays.challenge;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeTimeControlRules;
import client.datatypes.timecontrol.FischerTimeControl;
import client.ui.Assets;
import haxe.ui.components.Image;
import haxe.ui.containers.VBox;
import haxefolio.form.ChoiceGrid;
import haxefolio.form.FieldGroup;
import haxefolio.form.IntField;
import haxefolio.form.SteppedValueField;
import haxefolio.form.ToggleButton;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.DurationFormat;
import haxefolio.form.plumbing.FieldGroupDirection;
import haxefolio.form.plumbing.FieldState;

/**
    "Time control": presets, the "No time control" mode, and the initial time and bonus as fields
    the presets fill in. A preset is highlighted while the fields hold exactly its values. Writes
    straight into the draft (the fields' last valid values); `onEdit` follows every edit.
**/
class TimeControlSection extends VBox
{
    private final draft:ChallengeDraft;
    private final onEdit:Void->Void;
    private final presetGrid:ChoiceGrid<Int>;
    private final noTimeControlToggle:ToggleButton;
    private final startField:SteppedValueField<Int>;
    private final incrementField:SteppedValueField<Int>;
    private final setterPair:FieldGroup;
    private final setterGroup:FieldGroup;
    private final kindIcon:Image;

    public function new(draft:ChallengeDraft, onEdit:Void->Void)
    {
        super();

        this.addClass(StyleClass.CHALLENGE_FORM_SECTION);
        this.draft = draft;
        this.onEdit = onEdit;

        this.addComponent(new SectionHeading(phrase("section.time")));

        var presetOptions:Array<ChoiceOption<Int>> = [for (i in 0...ChallengeTimeControlRules.PRESETS.length) presetOption(i)];
        presetGrid = new ChoiceGrid<Int>(
            null,
            presetOptions,
            Single(null, onPresetSelected),
            StyleVars.CHALLENGE_OVERLAY_TIME_PRESETS_PER_ROW,
            StyleVars.CHALLENGE_OVERLAY_TIME_PRESET_GAP,
            false,
            null,
            Trailing
        );
        presetGrid.addClass(StyleClass.CHALLENGE_TIME_PRESETS);
        this.addComponent(presetGrid);

        var noTimeControl:String = phrase("no_time_control");
        noTimeControlToggle = new ToggleButton(onNoTimeControlToggled, {on: noTimeControl, off: noTimeControl}, !draft.timed);
        this.addComponent(noTimeControlToggle);

        startField = new SteppedValueField<Int>(
            phrase("field.initial_time"),
            draft.startSeconds,
            onStartSecondsChanged,
            DurationFormat.parse,
            DurationFormat.format,
            ChallengeTimeControlRules.stepStartSeconds,
            validateStartSeconds,
            phrase("hint.max_initial_time"),
            phrase("error.time_format"),
            draft.timed,
            onFieldValidityChanged
        );
        startField.percentWidth = StyleVars.CHALLENGE_OVERLAY_PAIR_FIELD_WIDTH_PERCENT;

        incrementField = IntField.create(
            phrase("field.bonus"),
            draft.incrementSeconds,
            onIncrementSecondsChanged,
            0,
            ChallengeTimeControlRules.MAX_INCREMENT_SECONDS,
            phrase("hint.max_bonus"),
            phrase("error.whole_seconds"),
            phrase("hint.max_bonus"),
            draft.timed,
            onFieldValidityChanged
        );
        incrementField.percentWidth = StyleVars.CHALLENGE_OVERLAY_PAIR_FIELD_WIDTH_PERCENT;

        setterPair = new FieldGroup([startField, incrementField], {expanded: Horizontal, collapsed: Vertical}, null, false, StyleVars.CHALLENGE_OVERLAY_TIME_SETTER_GAP);

        kindIcon = new Image();
        kindIcon.width = StyleVars.CHALLENGE_OVERLAY_KIND_ICON_SIZE;
        kindIcon.height = StyleVars.CHALLENGE_OVERLAY_KIND_ICON_SIZE;
        kindIcon.scaleMode = "fitinside";
        kindIcon.addClass(StyleClass.CHALLENGE_KIND_ICON);

        setterGroup = new FieldGroup([kindIcon, setterPair], FieldGroupDirection.Horizontal, null, true, StyleVars.CHALLENGE_OVERLAY_KIND_ICON_GAP);
        this.addComponent(setterGroup);

        refresh();
    }

    /** Whether both fields hold a value they could read, while the game is timed **/
    public function isValid():Bool
    {
        return !draft.timed || (startField.valid && incrementField.valid);
    }

    public function dispose():Void
    {
        presetGrid.dispose();
        setterPair.dispose();
        setterGroup.dispose();
    }

    private function presetOption(index:Int):ChoiceOption<Int>
    {
        var preset:FischerTimeControl = ChallengeTimeControlRules.PRESETS[index];
        return {
            value: index,
            label: '${Std.int(preset.startSeconds / 60)}+${preset.incrementSeconds}',
            icon: Assets.timeControlKindIcon(preset.getKind())
        };
    }

    private function onPresetSelected(index:Int):Void
    {
        var preset:FischerTimeControl = ChallengeTimeControlRules.PRESETS[index];

        draft.timed = true;
        draft.startSeconds = preset.startSeconds;
        draft.incrementSeconds = preset.incrementSeconds;

        noTimeControlToggle.on = false;
        startField.enabled = true;
        incrementField.enabled = true;
        startField.currentValue = preset.startSeconds;
        incrementField.currentValue = preset.incrementSeconds;

        refresh();
        onEdit();
    }

    private function onNoTimeControlToggled(on:Bool):Void
    {
        draft.timed = !on;
        startField.enabled = !on;
        incrementField.enabled = !on;
        refresh();
        onEdit();
    }

    private function onStartSecondsChanged(seconds:Int):Void
    {
        draft.startSeconds = seconds;
        refresh();
        onEdit();
    }

    private function onIncrementSecondsChanged(seconds:Int):Void
    {
        draft.incrementSeconds = seconds;
        refresh();
        onEdit();
    }

    private function onFieldValidityChanged(_:Bool):Void
    {
        refresh();
        onEdit();
    }

    private function validateStartSeconds(seconds:Int):FieldState<Int>
    {
        var message:Null<String> = null;

        if (!ChallengeTimeControlRules.isValidStartSeconds(seconds))
            message = seconds > ChallengeTimeControlRules.MAX_START_SECONDS ? phrase("hint.max_initial_time") : phrase("error.above_zero");

        return {value: seconds, valid: message == null, message: message, touched: false};
    }

    private function refresh():Void
    {
        presetGrid.selectSingle(isValid() ? ChallengeTimeControlRules.matchingPreset(draft) : null);
        kindIcon.resource = Assets.timeControlKindIcon(ChallengeTimeControlRules.kind(draft));
    }
}
