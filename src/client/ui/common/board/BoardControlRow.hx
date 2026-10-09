package client.ui.common.board;

import client.ui.Assets;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.piece.PieceKind;

using client.ui.ComponentExtension;

/**
    The board controls for touch screens, which lack a right button and modifier keys: the
    annotation mode (normal or a color), auto-promote and ask-about-chameleon. Only writes
    `BoardInputOptions`.
**/
class BoardControlRow extends Box
{
    /** Called with the new annotation color (`null` for the normal mode) after the user picks one **/
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
        addClass(StyleClass.BOARD_CONTROLS);

        var cross:Label = new Label();
        cross.text = "✕";
        cross.addClass(StyleClass.BOARD_CONTROL_CROSS);
        normalModeButton = createButton(cross, () -> selectAnnotationMode(null));
        addComponent(normalModeButton);

        for (color in AnnotationColor.createAll())
        {
            var disc:Box = new Box();
            disc.width = StyleVars.BOARD_CONTROL_COLOR_DISC_SIZE;
            disc.height = StyleVars.BOARD_CONTROL_COLOR_DISC_SIZE;
            disc.customStyle.backgroundColor = Std.parseInt("0x" + palette.annotationMark(color).substr(1));
            disc.customStyle.borderRadius = StyleVars.BOARD_CONTROL_COLOR_DISC_SIZE / 2;
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
        questionMark.addClass(StyleClass.BOARD_CONTROL_QUESTION);
        questionMark.horizontalAlign = "right";
        questionMark.verticalAlign = "bottom";
        var chameleonIcon:Box = new Box();
        chameleonIcon.width = StyleVars.BOARD_CONTROL_CHAMELEON_ICON_SIZE;
        chameleonIcon.height = StyleVars.BOARD_CONTROL_CHAMELEON_ICON_SIZE;
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

    /** A column if `vertical`, a row otherwise **/
    public function setVertical(vertical:Bool):Void
    {
        layoutName = vertical ? "vertical" : "horizontal";

        // centered along the board's side it sits on
        horizontalAlign = vertical ? null : "center";
        verticalAlign = vertical ? "center" : null;
    }

    /** Syncs the buttons' selected states with `options` **/
    public function refresh():Void
    {
        normalModeButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.annotationColorToggle == null);
        var colors:Array<AnnotationColor> = AnnotationColor.createAll();
        for (i in 0...colorButtons.length)
            colorButtons[i].setClass(StyleClass.BOARD_CONTROL_SELECTED, options.annotationColorToggle == colors[i]);
        autoPromoteButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.autoPromoteToggle);
        askChameleonButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.askChameleonToggle);
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
        button.addClass(StyleClass.BOARD_CONTROL);
        button.width = StyleVars.BOARD_CONTROL_BUTTON_WIDTH;
        button.height = StyleVars.BOARD_CONTROL_BUTTON_HEIGHT;
        button.customStyle.borderRadius = StyleVars.BOARD_CONTROL_BUTTON_RADIUS;
        button.invalidateComponentStyle();
        button.element.style.cursor = "pointer";

        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        // the button itself is always the event target
        content.element.style.pointerEvents = "none";
        button.addComponent(content);

        button.registerEvent(MouseEvent.CLICK, _ -> onSelect());
        return button;
    }

    // between the annotation mode, auto-promote and ask-about-chameleon sections
    private static function createSeparator():Label
    {
        var separator:Label = new Label();
        separator.text = "·";
        separator.addClass(StyleClass.BOARD_CONTROLS_SEPARATOR);
        separator.horizontalAlign = "center";
        separator.verticalAlign = "center";
        return separator;
    }

    private static function pieceArt(kind:PieceKind):Image
    {
        var art:Image = new Image();
        art.resource = Assets.pieceImage(kind, White);
        var aspectRatio:Float = Assets.pieceAspectRatio(kind);
        art.height = StyleVars.BOARD_CONTROL_ART_SIZE;
        art.width = StyleVars.BOARD_CONTROL_ART_SIZE * aspectRatio;
        art.horizontalAlign = "center";
        art.verticalAlign = "center";
        return art;
    }
}
