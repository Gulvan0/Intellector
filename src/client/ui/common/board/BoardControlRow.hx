package client.ui.common.board;

import client.Assets;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceKind;

/**
    The board controls for touch screens, which have no right button and no modifier keys: the
    annotation mode (a cross for the normal mode, where the primary button moves pieces, or one of
    the four colors to annotate with it), the auto-promote toggle and the ask-about-chameleon
    toggle, in three sections separated by dots. Only
    writes `BoardInputOptions`; `onAnnotationModeChanged` tells the assembler to rebind its tools.

    Laid out as a row (above the board) or a column (beside it), by `setVertical`.
**/
class BoardControlRow extends Box
{
    private static inline final BUTTON_WIDTH:Float = 40;
    private static inline final BUTTON_HEIGHT:Float = 36;
    // The style guide's chip radius.
    private static inline final BUTTON_RADIUS:Float = 5;
    // The style guide's spacing between items in a group.
    private static inline final SPACING:Float = 6;
    private static inline final COLOR_DISC_SIZE:Float = 22;
    private static inline final ART_SIZE:Float = 28;

    /**
        Called with the new annotation color (`null` for the normal mode) after the user picks one.
    **/
    public var onAnnotationModeChanged:Null<AnnotationColor>->Void = _ -> {};

    private final options:BoardInputOptions;

    private final normalModeButton:Box;
    private final colorButtons:Array<Box> = [];
    private final autoPromoteButton:Box;
    private final askChameleonButton:Box;

    public function new(options:BoardInputOptions, palette:BoardPalette)
    {
        super();
        this.options = options;
        addClass("intellector-board-controls");

        var cross:Label = new Label();
        cross.text = "✕";
        cross.addClass("intellector-board-control-cross");
        normalModeButton = createButton(cross, () -> selectAnnotationMode(null));
        addComponent(normalModeButton);

        for (color in AnnotationColor.createAll())
        {
            var disc:Box = new Box();
            disc.width = COLOR_DISC_SIZE;
            disc.height = COLOR_DISC_SIZE;
            disc.customStyle.backgroundColor = Std.parseInt("0x" + palette.annotationMark(color).substr(1));
            disc.customStyle.borderRadius = COLOR_DISC_SIZE / 2;
            disc.invalidateComponentStyle();

            var button:Box = createButton(disc, () -> selectAnnotationMode(color));
            colorButtons.push(button);
            addComponent(button);
        }

        addComponent(createSeparator());

        autoPromoteButton = createButton(pieceArt(Dominator), () -> {
            options.autoPromoteToggle = !options.autoPromoteToggle;
            refresh();
        });
        autoPromoteButton.tooltip = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.controls.auto_promote"));
        addComponent(autoPromoteButton);
        addComponent(createSeparator());

        var questionMark:Label = new Label();
        questionMark.text = "?";
        questionMark.addClass("intellector-board-control-question");
        questionMark.horizontalAlign = "right";
        questionMark.verticalAlign = "bottom";
        var chameleonIcon:Box = new Box();
        chameleonIcon.width = ART_SIZE + 8;
        chameleonIcon.height = ART_SIZE + 8;
        chameleonIcon.addComponent(pieceArt(Aggressor));
        chameleonIcon.addComponent(questionMark);

        askChameleonButton = createButton(chameleonIcon, () -> {
            options.askChameleonToggle = !options.askChameleonToggle;
            refresh();
        });
        askChameleonButton.tooltip = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.controls.ask_chameleon"));
        addComponent(askChameleonButton);

        setVertical(false);
        refresh();
    }

    /**
        A column if `vertical`, a row otherwise.
    **/
    public function setVertical(vertical:Bool):Void
    {
        layoutName = vertical ? "vertical" : "horizontal";

        // Centered along the board's side it sits on.
        horizontalAlign = vertical ? null : "center";
        verticalAlign = vertical ? "center" : null;

        // Box's own layout stacks children on top of each other; spacing only applies to the line layouts.
        customStyle.horizontalSpacing = SPACING;
        customStyle.verticalSpacing = SPACING;
        invalidateComponentStyle();
    }

    /**
        Brings the buttons' selected states in line with `options` (e.g. after the assembler set
        the toggles' starting values).
    **/
    public function refresh():Void
    {
        setSelected(normalModeButton, options.annotationColorToggle == null);
        var colors:Array<AnnotationColor> = AnnotationColor.createAll();
        for (i in 0...colorButtons.length)
            setSelected(colorButtons[i], options.annotationColorToggle == colors[i]);
        setSelected(autoPromoteButton, options.autoPromoteToggle);
        setSelected(askChameleonButton, options.askChameleonToggle);
    }

    private function selectAnnotationMode(color:Null<AnnotationColor>):Void
    {
        if (options.annotationColorToggle == color)
            return;

        options.annotationColorToggle = color;
        refresh();
        onAnnotationModeChanged(color);
    }

    private static function createButton(content:haxe.ui.core.Component, onSelect:Void->Void):Box
    {
        var button:Box = new Box();
        button.addClass("intellector-board-control");
        button.width = BUTTON_WIDTH;
        button.height = BUTTON_HEIGHT;
        button.customStyle.borderRadius = BUTTON_RADIUS;
        button.invalidateComponentStyle();
        button.element.style.cursor = "pointer";

        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        // The button itself is always the event target.
        content.element.style.pointerEvents = "none";
        button.addComponent(content);

        button.registerEvent(MouseEvent.CLICK, _ -> onSelect());
        return button;
    }

    // Between the sections: the annotation mode (normal or a color), auto-promote, ask about chameleon.
    private static function createSeparator():Label
    {
        var separator:Label = new Label();
        separator.text = "·";
        separator.addClass("intellector-board-controls-separator");
        separator.horizontalAlign = "center";
        separator.verticalAlign = "center";
        return separator;
    }

    private static function setSelected(button:Box, selected:Bool):Void
    {
        if (selected)
            button.addClass("intellector-board-control-selected");
        else
            button.removeClass("intellector-board-control-selected");
    }

    private static function pieceArt(kind:PieceKind):Image
    {
        var art:Image = new Image();
        art.resource = Assets.pieceImage(kind, White);
        var aspectRatio:Float = Assets.pieceAspectRatio(kind);
        art.height = ART_SIZE;
        art.width = ART_SIZE * aspectRatio;
        art.horizontalAlign = "center";
        art.verticalAlign = "center";
        return art;
    }
}
