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
    // a pen over a stroke; both the stroke and the pen's tip and band take the current CSS color
    private static final PEN_ICON_SVG:String = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" aria-hidden="true" style="display: block; width: 100%; height: 100%; overflow: visible;">'
        + '<path d="M6 27.5 H25" fill="none" stroke="currentColor" stroke-opacity="0.4" stroke-width="5" stroke-linecap="round"/>'
        + '<g transform="translate(16 14) rotate(45)" stroke="#2a211a" stroke-width="1.5" stroke-linejoin="round">'
        + '<path d="M-5.5 -10.8Q-5.5 -13 -3.3 -13L3.3 -13Q5.5 -13 5.5 -10.8L5.5 4.3Q5.5 6.5 4.32 8.36L3.18 10.14Q2 12 -0.2 12L-3.3 12Q-5.5 12 -5.5 9.8Z" fill="#fffefb" stroke="none"/>'
        + '<path d="M-5.5 1L5.5 1L5.5 4.3Q5.5 6.5 4.32 8.36L3.18 10.14Q2 12 -0.2 12L-3.3 12Q-5.5 12 -5.5 9.8Z" fill="currentColor" stroke="none"/>'
        + '<rect x="-5.5" y="-8" width="11" height="3" fill="currentColor"/>'
        + '<path d="M-5.5 1H5.5" fill="none"/>'
        + '<path d="M-5.5 -10.8Q-5.5 -13 -3.3 -13L3.3 -13Q5.5 -13 5.5 -10.8L5.5 4.3Q5.5 6.5 4.32 8.36L3.18 10.14Q2 12 -0.2 12L-3.3 12Q-5.5 12 -5.5 9.8Z" fill="none"/>'
        + '</g></svg>';

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
            var pen:Box = new Box();
            pen.width = StyleVars.BOARD_CONTROL_PEN_ICON_SIZE;
            pen.height = StyleVars.BOARD_CONTROL_PEN_ICON_SIZE;
            pen.element.innerHTML = PEN_ICON_SVG;
            pen.element.style.color = palette.annotationMark(color);

            var button:Box = createButton(pen, () -> selectAnnotationMode(color));
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

    /** A column of fixed-size buttons if `vertical`, otherwise a row as wide as the board, its buttons sharing the width **/
    public function setVertical(vertical:Bool):Void
    {
        layoutName = vertical ? "vertical" : "horizontal";

        // centered along the board's side it sits on
        horizontalAlign = vertical ? null : "center";
        verticalAlign = vertical ? "center" : null;

        percentWidth = vertical ? null : 100;
        var buttons:Array<Box> = [normalModeButton].concat(colorButtons).concat([autoPromoteButton, askChameleonButton]);
        for (button in buttons)
        {
            if (vertical)
            {
                button.percentWidth = null;
                button.width = StyleVars.BOARD_CONTROL_BUTTON_WIDTH;
            }
            else
            {
                button.width = null; // the percent layout bypasses the setter, so a stale width would make the next identical one a no-op
                button.percentWidth = 100 / buttons.length;
            }
        }
        invalidateComponentLayout(); // a null size alone doesn't return the column to its auto width
    }

    /** Auto-promote only matters to a user who moves pieces **/
    public function setAutoPromoteEnabled(enabled:Bool):Void
    {
        autoPromoteButton.disabled = !enabled;
    }

    /** Ask-about-chameleon only matters for premoves **/
    public function setAskChameleonEnabled(enabled:Bool):Void
    {
        askChameleonButton.disabled = !enabled;
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
        button.height = StyleVars.BOARD_CONTROL_BUTTON_HEIGHT;
        button.customStyle.borderRadius = StyleVars.BOARD_CONTROL_BUTTON_RADIUS;
        button.invalidateComponentStyle();

        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        // the button itself is always the event target
        content.element.style.pointerEvents = "none";
        button.addComponent(content);

        button.registerEvent(MouseEvent.CLICK, _ -> onSelect());
        return button;
    }

    // between the annotation mode, auto-promote and ask-about-chameleon sections
    private static function createSeparator():Box
    {
        var dot:Box = new Box();
        dot.addClass(StyleClass.BOARD_CONTROLS_SEPARATOR);
        dot.width = StyleVars.BOARD_CONTROLS_SEPARATOR_DIAMETER;
        dot.height = StyleVars.BOARD_CONTROLS_SEPARATOR_DIAMETER;
        dot.customStyle.borderRadius = StyleVars.BOARD_CONTROLS_SEPARATOR_DIAMETER / 2;
        dot.invalidateComponentStyle();
        dot.horizontalAlign = "center";
        dot.verticalAlign = "center";

        // widens the gap to the neighboring buttons along either orientation
        var separator:Box = new Box();
        separator.width = StyleVars.BOARD_CONTROLS_SEPARATOR_DIAMETER + 2 * StyleVars.BOARD_CONTROLS_SEPARATOR_MARGIN;
        separator.height = StyleVars.BOARD_CONTROLS_SEPARATOR_DIAMETER + 2 * StyleVars.BOARD_CONTROLS_SEPARATOR_MARGIN;
        separator.horizontalAlign = "center";
        separator.verticalAlign = "center";
        separator.addComponent(dot);
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
