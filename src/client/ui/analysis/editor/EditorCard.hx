package client.ui.analysis.editor;

import client.datatypes.variations.PositionDraft;
import client.formatters.Plurals;
import client.ui.game.GameButtons;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.locale.LocaleManager;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceColor;

using client.ui.ComponentExtension;

typedef EditorCardHandlers =
{
    onSideChosen:PieceColor->Void,
    onImport:Void->Void,
    onClear:Void->Void,
    onReset:Void->Void,
    onStarting:Void->Void,
    onApply:Void->Void,
    onDiscard:Void->Void
}

/**
    The position editor's controls: side to move, the position actions, and Apply / Discard under
    the hint on what applying does (or why it can't be applied).
**/
class EditorCard extends VBox
{
    private final sideOptions:Map<PieceColor, Box> = [];
    private final positionLabel:Label;
    private final actionGrid:Grid;
    private final clearButton:Button;
    private final resetButton:Button;
    private final startingButton:Button;
    private final footerHint:Label;
    private final decisionRow:HBox;
    private final applyButton:Button;
    private final discardButton:Button;
    private final sideField:Box;
    private final sideTrack:HBox;

    private var moveCount:Int = 0;
    private var valid:Bool = true;
    private var compact:Bool = false;

    public function new(handlers:EditorCardHandlers)
    {
        super();
        percentWidth = 100;
        addClass(StyleClass.GAME_CARD);
        addClass(StyleClass.EDITOR_CARD);

        var heading:VBox = new VBox();
        heading.percentWidth = 100;
        heading.addClass(StyleClass.EDITOR_FIELD);
        addComponent(heading);
        var title:Label = new Label();
        title.text = LocaleUtils.localeBinding("intellector.analysis.editor.title");
        title.addClass(StyleClass.GAME_CARD_TITLE);
        heading.addComponent(title);
        var lockHint:Label = new Label();
        lockHint.percentWidth = 100;
        lockHint.text = LocaleUtils.localeBinding("intellector.analysis.editor.locked_hint");
        lockHint.addClass(StyleClass.GAME_HINT);
        lockHint.addClass(StyleClass.EDITOR_WRAPPING_HINT);
        heading.addComponent(lockHint);

        sideField = new Box();
        sideField.percentWidth = 100;
        sideField.addClass(StyleClass.EDITOR_FIELD);
        addComponent(sideField);
        var sideLabel:Label = new Label();
        sideLabel.text = LocaleUtils.localeBinding("intellector.analysis.editor.side");
        sideLabel.addClass(StyleClass.EDITOR_FIELD_LABEL);
        sideLabel.verticalAlign = "center";
        sideField.addComponent(sideLabel);
        sideTrack = new HBox();
        sideTrack.percentWidth = 100;
        sideTrack.addClass(StyleClass.GAME_SEGMENTS);
        for (color in [White, Black])
        {
            var option:Box = createSideOption(color, handlers.onSideChosen);
            sideOptions.set(color, option);
            sideTrack.addComponent(option);
        }
        sideField.addComponent(sideTrack);

        var positionField:VBox = new VBox();
        positionField.percentWidth = 100;
        positionField.addClass(StyleClass.EDITOR_FIELD);
        addComponent(positionField);
        positionLabel = new Label();
        positionLabel.text = LocaleUtils.localeBinding("intellector.analysis.editor.position");
        positionLabel.addClass(StyleClass.EDITOR_FIELD_LABEL);
        positionField.addComponent(positionLabel);
        actionGrid = new Grid();
        actionGrid.percentWidth = 100;
        actionGrid.addClass(StyleClass.EDITOR_ACTIONS);
        positionField.addComponent(actionGrid);
        var importButton:Button = positionAction("import", "intellector.analysis.editor.import", handlers.onImport);
        clearButton = positionAction("clear", "intellector.analysis.editor.clear", handlers.onClear);
        resetButton = positionAction("reset", "intellector.analysis.editor.reset", handlers.onReset);
        startingButton = positionAction("starting_position", "intellector.analysis.editor.starting", handlers.onStarting);
        for (button in [importButton, clearButton, resetButton, startingButton])
            actionGrid.addComponent(button);

        var footer:VBox = new VBox();
        footer.percentWidth = 100;
        footer.addClass(StyleClass.EDITOR_FOOTER);
        addComponent(footer);
        footerHint = new Label();
        footerHint.percentWidth = 100;
        footerHint.addClass(StyleClass.GAME_HINT);
        footerHint.addClass(StyleClass.EDITOR_WRAPPING_HINT);
        footer.addComponent(footerHint);
        LocaleManager.instance.registerComponent(footerHint, "text", footerText);

        decisionRow = new HBox();
        decisionRow.percentWidth = 100;
        decisionRow.addClass(StyleClass.GAME_ACTIONS_ROW);
        footer.addComponent(decisionRow);
        applyButton = new Button();
        applyButton.text = LocaleUtils.localeBinding("intellector.analysis.editor.apply");
        applyButton.addClass(StyleClass.GAME_BUTTON);
        applyButton.addClass(StyleClass.GAME_BUTTON_PRIMARY);
        applyButton.percentWidth = 50;
        applyButton.onClick = _ -> handlers.onApply();
        discardButton = new Button();
        discardButton.text = LocaleUtils.localeBinding("intellector.analysis.editor.discard");
        discardButton.addClass(StyleClass.GAME_BUTTON);
        discardButton.percentWidth = 50;
        discardButton.onClick = _ -> handlers.onDiscard();

        setCompact(false);
    }

    /** `moveCount`: how many moves applying a different position would clear **/
    public function refresh(draft:PositionDraft, moveCount:Int):Void
    {
        this.moveCount = moveCount;
        valid = draft.isValid();

        for (color => option in sideOptions)
            option.setClass(StyleClass.GAME_SEGMENT_ON, draft.position.turnColor == color);
        clearButton.disabled = draft.isClear();
        resetButton.disabled = !draft.isChanged();
        startingButton.disabled = draft.isStarting();
        applyButton.disabled = !valid;
        LocaleManager.instance.refreshFor(footerHint); // assigning the text would drop its locale binding
    }

    /** Compact: side to move on one row, the actions in a 2×2 grid, Apply on the right **/
    public function setCompact(compact:Bool):Void
    {
        this.compact = compact;
        this.setClass(StyleClass.EDITOR_CARD_COMPACT, compact);
        positionLabel.hidden = compact;
        actionGrid.columns = compact ? 2 : 1;
        GameButtons.setCaption(startingButton, compact ? "intellector.analysis.editor.starting_short" : "intellector.analysis.editor.starting", true);
        startingButton.tooltip = LocaleUtils.localeBinding("intellector.analysis.editor.starting");

        sideField.layoutName = compact ? "horizontal" : "vertical";
        if (!compact)
        {
            // the compact rule's fixed width outlives the rule
            sideTrack.width = null;
            sideTrack.percentWidth = 100;
            sideTrack.invalidateComponentLayout();
        }

        for (button in [applyButton, discardButton])
            if (button.parentComponent != null)
                decisionRow.removeComponent(button, false);
        decisionRow.addComponent(compact ? discardButton : applyButton);
        decisionRow.addComponent(compact ? applyButton : discardButton);
    }

    private function footerText():String
    {
        if (!valid)
            return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.editor.invalid"));
        if (moveCount == 0)
            return LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.analysis.editor.new_analysis"));

        var key:String = Plurals.key("intellector.analysis.editor.clears_moves", moveCount, Preferences.language.get());
        return LocaleUtils.resolveText(LocaleUtils.localeBinding(key), moveCount);
    }

    private function createSideOption(color:PieceColor, onSideChosen:PieceColor->Void):Box
    {
        var option:Box = new Box();
        option.percentWidth = 50;
        option.addClass(StyleClass.GAME_SEGMENT);
        option.onClick = _ -> onSideChosen(color);
        option.trackHover();

        var content:HBox = new HBox();
        content.addClass(StyleClass.GAME_SEGMENT_CONTENT);
        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        option.addComponent(content);

        var ring:Box = new Box();
        ring.addClass(StyleClass.EDITOR_SIDE_RING);
        ring.verticalAlign = "center";
        content.addComponent(ring);

        var ringGap:Box = new Box();
        ringGap.addClass(StyleClass.EDITOR_SIDE_RING_GAP);
        ringGap.horizontalAlign = "center";
        ringGap.verticalAlign = "center";
        ring.addComponent(ringGap);

        var disc:Box = new Box();
        disc.addClass(StyleClass.EDITOR_SIDE_DISC);
        disc.addClass(color == White ? StyleClass.VARIATION_DISC_WHITE : StyleClass.VARIATION_DISC_BLACK);
        disc.horizontalAlign = "center";
        disc.verticalAlign = "center";
        ringGap.addComponent(disc);

        var label:Label = new Label();
        label.text = LocaleUtils.localeBinding('intellector.common.color.${color.getName().toLowerCase()}');
        label.verticalAlign = "center";
        content.addComponent(label);
        return option;
    }

    private function positionAction(iconName:String, captionKey:String, onPress:Void->Void):Button
    {
        var button:Button = GameButtons.actionWithIcon(Assets.analysisIcon(iconName), captionKey, onPress);
        button.percentWidth = 100;
        button.addClass(StyleClass.EDITOR_ACTION);
        return button;
    }
}
