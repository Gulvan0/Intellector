package client.ui.common.overlays.challenge.bot;

import client.GroupedLocaleResolvers.challengeOverlay as phrase;
import client.datatypes.bot.BotKind;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.bot.BotKinds;
import client.logic.bot.BotStrengthRules;
import client.logic.bot.BotThinkCapRules;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxefolio.LocaleUtils;
import haxefolio.ResponsivityController;
import haxefolio.form.ChoiceRow;
import haxefolio.form.SteppedValueField;
import haxefolio.form.plumbing.ChoiceButton;
import haxefolio.form.plumbing.ChoiceOption;
import haxefolio.form.plumbing.DurationFormat;
import haxefolio.form.plumbing.FieldState;
import haxefolio.structure.ActionButton;
import morestd.Detachable;

/**
    Setting up the chosen bot: its portrait and name, what it's about, the way back to choosing,
    the strength and the think time cap. The portrait stands beside the rest in the expanded
    layout, above the fields otherwise. Writes straight into the draft; `onEdit` follows every edit.
**/
class BotSetup extends Box
{
    private final draft:ChallengeDraft;
    private final onEdit:Void->Void;
    private final portrait:Box;
    private final portraitImage:Image;
    private final nameLabel:Label;
    private final aboutButton:BotAboutButton;
    private final changeButton:ActionButton;
    private final strengthRow:ChoiceRow<Int>;
    private final capField:SteppedValueField<Int>;
    private final noCapButton:ChoiceButton;
    private final bindings:Array<Detachable>;
    private var arrangement:Null<Component> = null;

    public function new(draft:ChallengeDraft, onChangeBot:Void->Void, onEdit:Void->Void)
    {
        super();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.draft = draft;
        this.onEdit = onEdit;

        portraitImage = new Image();
        portraitImage.percentWidth = 100;
        portraitImage.percentHeight = 100;
        portraitImage.scaleMode = FIT_INSIDE;
        portraitImage.imageVerticalAlign = BOTTOM;

        portrait = new Box();
        portrait.addClass(StyleClass.CHALLENGE_BOT_PORTRAIT);
        portrait.addComponent(portraitImage);

        nameLabel = new Label();
        nameLabel.verticalAlign = "center";
        nameLabel.addClass(StyleClass.CHALLENGE_BOT_NAME);

        aboutButton = new BotAboutButton(openAbout);
        aboutButton.verticalAlign = "center";

        changeButton = new ActionButton(phrase("bot.change"), onChangeBot);
        changeButton.verticalAlign = "center";
        changeButton.addClass(StyleClass.CHALLENGE_BOT_CHANGE);

        var strengthOptions:Array<ChoiceOption<Int>> = [
            for (strength in BotStrengthRules.MIN_STRENGTH...BotStrengthRules.MAX_STRENGTH + 1)
                {value: strength, label: Std.string(strength)}
        ];
        strengthRow = new ChoiceRow<Int>(phrase("bot.field.strength"), strengthOptions, draft.botStrength, onStrengthSelected);
        strengthRow.hint = phrase("bot.hint.strength");
        strengthRow.joinButtons();
        strengthRow.addClass(StyleClass.CHALLENGE_BOT_STRENGTH);

        capField = new SteppedValueField<Int>(
            phrase("bot.field.cap"),
            draft.botCapSeconds,
            onCapSecondsChanged,
            DurationFormat.parse,
            DurationFormat.format,
            BotThinkCapRules.step,
            validateCapSeconds,
            capHint(),
            phrase("error.time_format"),
            draft.botCapEnabled,
            onCapValidityChanged
        );

        noCapButton = new ChoiceButton(phrase("bot.no_cap"), onNoCapToggled, null, Leading, !draft.botCapEnabled);
        noCapButton.addClass(StyleClass.CHALLENGE_BOT_NO_CAP);
        capField.addBesideStepper(noCapButton, StyleVars.CHALLENGE_OVERLAY_BOT_NO_CAP_GAP);

        bindings = [
            ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_CARDS_SIDEWAYS, arrange),
            ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_PORTRAIT_SIZE, size -> {
                portrait.width = size;
                portrait.height = size;
            }),
            ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_SMALL_CONTROL_HEIGHT, height -> {
                aboutButton.width = height;
                aboutButton.height = height;
                changeButton.height = height;
            }),
            ResponsivityController.bind(StyleVars.CHALLENGE_OVERLAY_BOT_NO_CAP_WIDTH, width -> noCapButton.width = width)
        ];

        showBot();
    }

    /** Whether the cap holds a value it could read, while it is on **/
    public function isValid():Bool
    {
        return !draft.botCapEnabled || capField.valid;
    }

    /** Follows a change of `draft.bot` or of the strength it forced **/
    public function showBot():Void
    {
        var kind:Null<BotKind> = draft.bot;
        if (kind == null)
            return;

        portraitImage.resource = BotKinds.avatarPath(kind);
        nameLabel.text = BotKinds.displayName(kind);
        aboutButton.setLabel(LocaleUtils.localeBinding("intellector.overlay.challenge.bot.about", BotKinds.displayName(kind)));
        strengthRow.setOptionEnabled(BotStrengthRules.MAX_STRENGTH, BotStrengthRules.isAvailable(kind, BotStrengthRules.MAX_STRENGTH));
        strengthRow.select(draft.botStrength);
    }

    public function dispose():Void
    {
        for (binding in bindings)
            binding.detach();
        strengthRow.dispose();
    }

    // side by side: portrait | name row, strength, cap; otherwise: portrait | name over Change bot, then the fields
    private function arrange(sideBySide:Bool):Void
    {
        for (component in [portrait, nameLabel, aboutButton, changeButton, strengthRow, capField])
            if (component.parentComponent != null)
                component.parentComponent.removeComponent(component, false);

        if (arrangement != null)
            this.removeComponent(arrangement);

        var nameLine:HBox = new HBox();
        nameLine.horizontalSpacing = 2;
        nameLine.addComponent(nameLabel);
        nameLine.addComponent(aboutButton);

        if (sideBySide)
        {
            var spacer:Box = new Box();
            spacer.percentWidth = 100;

            var nameRow:HBox = new HBox();
            nameRow.percentWidth = 100;
            nameRow.addComponent(nameLine);
            nameRow.addComponent(spacer);
            nameRow.addComponent(changeButton);

            var fields:VBox = new VBox();
            fields.percentWidth = 100;
            fields.verticalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_SETUP_ROW_GAP.resolve(Expanded);
            fields.addComponent(nameRow);
            fields.addComponent(strengthRow);
            fields.addComponent(capField);

            var row:HBox = new HBox();
            row.percentWidth = 100;
            row.horizontalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_PORTRAIT_GAP;
            row.addComponent(portrait);
            row.addComponent(fields);
            arrangement = row;
        }
        else
        {
            var nameColumn:VBox = new VBox();
            nameColumn.percentWidth = 100;
            nameColumn.verticalAlign = "center";
            nameColumn.verticalSpacing = 5;
            nameColumn.addComponent(nameLine);
            nameColumn.addComponent(changeButton);

            var top:HBox = new HBox();
            top.percentWidth = 100;
            top.horizontalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_PORTRAIT_GAP;
            top.addComponent(portrait);
            top.addComponent(nameColumn);

            var column:VBox = new VBox();
            column.percentWidth = 100;
            column.verticalSpacing = StyleVars.CHALLENGE_OVERLAY_BOT_SETUP_ROW_GAP.resolve(Collapsed);
            column.addComponent(top);
            column.addComponent(strengthRow);
            column.addComponent(capField);
            arrangement = column;
        }

        this.addComponent(arrangement);
    }

    private function openAbout():Void
    {
        if (draft.bot != null)
            BotAboutOverlay.present(draft.bot);
    }

    private function onStrengthSelected(strength:Int):Void
    {
        draft.botStrength = strength;
        onEdit();
    }

    private function onNoCapToggled():Void
    {
        draft.botCapEnabled = !noCapButton.selected;
        capField.enabled = draft.botCapEnabled;
        capField.hint = capHint();
        onEdit();
    }

    private function onCapSecondsChanged(seconds:Int):Void
    {
        draft.botCapSeconds = seconds;
        onEdit();
    }

    private function onCapValidityChanged(_:Bool):Void
    {
        onEdit();
    }

    private function capHint():String
    {
        return draft.botCapEnabled ? phrase("bot.hint.cap_range") : phrase("bot.hint.no_cap");
    }

    private function validateCapSeconds(seconds:Int):FieldState<Int>
    {
        var message:Null<String> = null;

        if (seconds < BotThinkCapRules.MIN_SECONDS)
            message = phrase("bot.error.cap_min");
        else if (seconds > BotThinkCapRules.MAX_SECONDS)
            message = phrase("bot.error.cap_max");

        return {value: seconds, valid: message == null, message: message, touched: false};
    }
}
