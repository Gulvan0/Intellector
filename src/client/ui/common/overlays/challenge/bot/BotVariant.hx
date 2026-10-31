package client.ui.common.overlays.challenge.bot;

import client.datatypes.bot.BotKind;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.logic.challenge.creation.ChallengeDraftRules;
import haxe.ui.containers.Box;

/**
    Against bot's part of the type slot, in two phases sharing its height: choosing a bot, then
    setting it up. Opens on setting up the remembered bot, if any. Writes straight into the draft;
    `onEdit` follows every edit, the phase changes included.
**/
class BotVariant extends Box
{
    private final draft:ChallengeDraft;
    private final onEdit:Void->Void;
    private final picker:BotPicker;
    private final setup:BotSetup;

    public function new(draft:ChallengeDraft, onEdit:Void->Void)
    {
        super();

        this.percentWidth = 100;
        this.percentHeight = 100;
        this.draft = draft;
        this.onEdit = onEdit;

        picker = new BotPicker(draft.bot, onBotPicked);
        setup = new BotSetup(draft, onChangeBot, onEdit);
        this.addComponent(picker);
        this.addComponent(setup);

        showChoosing(draft.bot == null);
    }

    /** Whether a bot is set up with values its fields could read **/
    public function isValid():Bool
    {
        return picker.hidden && setup.isValid();
    }

    public function dispose():Void
    {
        picker.dispose();
        setup.dispose();
    }

    private function onBotPicked(kind:BotKind):Void
    {
        ChallengeDraftRules.selectBot(draft, kind);
        picker.current = kind;
        setup.showBot();
        showChoosing(false);
        onEdit();
    }

    private function onChangeBot():Void
    {
        showChoosing(true);
        onEdit();
    }

    private function showChoosing(choosing:Bool):Void
    {
        picker.hidden = !choosing;
        setup.hidden = choosing;
    }
}
