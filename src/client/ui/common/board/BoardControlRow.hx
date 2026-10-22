package client.ui.common.board;

import client.ui.Assets;
import haxe.Resource;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxefolio.LocaleUtils;
import js.Browser;
import js.html.Animation;

using client.ui.ComponentExtension;

/**
    The board controls for touch screens, which lack a right button and modifier keys. The default
    page holds the annotation entry, auto-promote, the chameleon mode and the premove chameleon
    choice; the annotation page (the normal mode and the colors) replaces it while a color is
    selected. Only writes `BoardInputOptions`.
**/
class BoardControlRow extends Box
{
    /** Called with the new annotation color (`null` for the normal mode) after the user picks one **/
    public var onAnnotationModeChanged:Null<AnnotationColor>->Void = _ -> {};

    private final options:BoardInputOptions;

    private final defaultPage:Box;
    private final annotateButton:Box;
    private final autoPromoteButton:Box;
    private final chameleonModeSegments:Box;
    private final chameleonModeButtons:Array<Box> = [];
    private final premoveChameleonButton:Box;

    private final annotationPage:Box;
    private final normalModeButton:Box;
    private final colorButtons:Array<Box> = [];

    private var lastAnnotationColor:AnnotationColor = Red;
    private var pageTransition:Null<Animation> = null;

    public function new(options:BoardInputOptions, palette:BoardPalette)
    {
        super();
        this.options = options;
        addClass(StyleClass.BOARD_CONTROLS);

        defaultPage = createPage();

        annotateButton = createButton(controlIcon("annotate"), "annotate", () -> selectAnnotationMode(lastAnnotationColor));
        defaultPage.addComponent(annotateButton);
        defaultPage.addComponent(createSeparator());

        autoPromoteButton = createButton(controlIcon("auto_promotion"), "auto_promote", () -> {
            options.autoPromoteToggle = !options.autoPromoteToggle;
            syncSelection();
        });
        defaultPage.addComponent(autoPromoteButton);
        defaultPage.addComponent(createSeparator());

        chameleonModeSegments = new Box();
        chameleonModeSegments.addClass(StyleClass.BOARD_CONTROL_SEGMENTS);
        chameleonModeSegments.customStyle.borderRadius = StyleVars.BOARD_CONTROL_BUTTON_RADIUS;
        chameleonModeSegments.invalidateComponentStyle();
        for (mode in ChameleonMode.createAll())
        {
            var name:String = chameleonModeName(mode);
            var button:Box = createButton(controlIcon(name), name, () -> {
                options.chameleonModeToggle = mode;
                syncSelection();
            }, StyleClass.BOARD_CONTROL_SEGMENT);
            button.height = StyleVars.BOARD_CONTROL_BUTTON_HEIGHT - 2; // inside the tray's border
            chameleonModeButtons.push(button);
            chameleonModeSegments.addComponent(button);
        }
        defaultPage.addComponent(chameleonModeSegments);
        defaultPage.addComponent(createSeparator());

        premoveChameleonButton = createButton(controlIcon("ask_premove_aura"), "premove_aura", () -> {
            options.askPremoveChameleonToggle = !options.askPremoveChameleonToggle;
            syncSelection();
        });
        defaultPage.addComponent(premoveChameleonButton);

        annotationPage = createPage();

        var cross:Label = new Label();
        cross.text = "✕";
        cross.addClass(StyleClass.BOARD_CONTROL_CROSS);
        normalModeButton = createButton(cross, null, () -> selectAnnotationMode(null));
        annotationPage.addComponent(normalModeButton);

        for (color in AnnotationColor.createAll())
        {
            var pen:Box = new Box();
            pen.width = StyleVars.BOARD_CONTROL_ICON_SIZE;
            pen.height = StyleVars.BOARD_CONTROL_ICON_SIZE;
            // a pen over a stroke; the svg takes the current CSS color for the stroke, the pen's tip and band
            pen.element.innerHTML = Resource.getString("annotate_generic");
            pen.element.style.color = palette.annotationMark(color);

            var button:Box = createButton(pen, null, () -> selectAnnotationMode(color));
            colorButtons.push(button);
            annotationPage.addComponent(button);
        }

        addComponent(defaultPage);
        addComponent(annotationPage);
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

        var segmentCount:Int = chameleonModeButtons.length;
        layOutPage(defaultPage, vertical, [annotateButton, autoPromoteButton, chameleonModeSegments, premoveChameleonButton], [1, 1, segmentCount, 1]);
        layOutPage(annotationPage, vertical, [normalModeButton].concat(colorButtons), [for (_ in 0...colorButtons.length + 1) 1]);

        chameleonModeSegments.layoutName = layoutName;
        for (button in chameleonModeButtons)
            button.percentWidth = vertical ? 100 : 100 / segmentCount;
        roundSegmentEnds(vertical);

        invalidateComponentLayout(); // a null size alone doesn't return the column to its auto width
    }

    /** Auto-promote and the chameleon mode only matter to a user who moves pieces **/
    public function setMoveControlsEnabled(enabled:Bool):Void
    {
        autoPromoteButton.disabled = !enabled;
        chameleonModeSegments.disabled = !enabled;
    }

    /** The premove chameleon choice only matters while premoves are possible **/
    public function setPremoveChameleonEnabled(enabled:Bool):Void
    {
        premoveChameleonButton.disabled = !enabled;
    }

    /** Syncs the buttons' selected states and the shown page with `options`, without animating **/
    public function refresh():Void
    {
        syncSelection();
        showPage(options.annotationColorToggle != null, false);
    }

    private function syncSelection():Void
    {
        autoPromoteButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.autoPromoteToggle);
        var modes:Array<ChameleonMode> = ChameleonMode.createAll();
        for (i in 0...chameleonModeButtons.length)
            chameleonModeButtons[i].setClass(StyleClass.BOARD_CONTROL_SELECTED, options.chameleonModeToggle == modes[i]);
        premoveChameleonButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.askPremoveChameleonToggle);

        normalModeButton.setClass(StyleClass.BOARD_CONTROL_SELECTED, options.annotationColorToggle == null);
        var colors:Array<AnnotationColor> = AnnotationColor.createAll();
        for (i in 0...colorButtons.length)
            colorButtons[i].setClass(StyleClass.BOARD_CONTROL_SELECTED, options.annotationColorToggle == colors[i]);
    }

    // entering or leaving the annotation mode switches to its page
    private function selectAnnotationMode(color:Null<AnnotationColor>):Void
    {
        var previous:Null<AnnotationColor> = options.annotationColorToggle;
        if (previous == color)
            return;

        options.annotationColorToggle = color;
        if (color != null)
            lastAnnotationColor = color;

        syncSelection();
        if ((previous == null) != (color == null))
            showPage(color != null, true);
        onAnnotationModeChanged(color);
    }

    /*
        The shown page slides out and fades toward the row's far end when going to the annotation page,
        toward the near one when leaving it; then the other page slides in after it.
    */
    private function showPage(annotationPageShown:Bool, animated:Bool):Void
    {
        if (pageTransition != null)
        {
            pageTransition.cancel();
            pageTransition = null;
        }

        var incoming:Box = annotationPageShown ? annotationPage : defaultPage;
        var outgoing:Box = annotationPageShown ? defaultPage : annotationPage;
        if (!incoming.hidden || !animated || prefersReducedMotion())
        {
            outgoing.hidden = true;
            incoming.hidden = false;
            return;
        }

        var direction:Float = annotationPageShown ? 1 : -1;
        var leaving:Animation = slide(outgoing, 0, direction, 1, 0, StyleVars.BOARD_CONTROLS_PAGE_OUT_MS, "ease-in");
        leaving.onfinish = () -> {
            outgoing.hidden = true;
            incoming.hidden = false;
            var entering:Animation = slide(incoming, -direction, 0, 0, 1, StyleVars.BOARD_CONTROLS_PAGE_IN_MS, "ease-out");
            entering.onfinish = () -> {
                pageTransition = null;
            };
            pageTransition = entering;
        };
        pageTransition = leaving;
    }

    // `fromShift`/`toShift` are in page slide lengths along the row's axis
    private function slide(page:Box, fromShift:Float, toShift:Float, fromOpacity:Float, toOpacity:Float, durationMs:Float, easing:String):Animation
    {
        var axis:String = layoutName == "vertical" ? "Y" : "X";
        var distance:Float = StyleVars.BOARD_CONTROLS_PAGE_SLIDE;
        var keyframes:Array<{opacity:Float, transform:String, easing:String}> = [
            {opacity: fromOpacity, transform: 'translate$axis(${fromShift * distance}px)', easing: easing},
            {opacity: toOpacity, transform: 'translate$axis(${toShift * distance}px)', easing: easing}
        ];
        return page.element.animate(keyframes, durationMs);
    }

    private static function prefersReducedMotion():Bool
    {
        return Browser.window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    }

    private static function createPage():Box
    {
        var page:Box = new Box();
        page.addClass(StyleClass.BOARD_CONTROLS_PAGE);
        return page;
    }

    // `slots` is each item's share of the row's width, in buttons
    private static function layOutPage(page:Box, vertical:Bool, items:Array<Box>, slots:Array<Int>):Void
    {
        page.layoutName = vertical ? "vertical" : "horizontal";
        page.percentWidth = vertical ? null : 100;

        var totalSlots:Int = 0;
        for (count in slots)
            totalSlots += count;

        for (i in 0...items.length)
        {
            if (vertical)
            {
                items[i].percentWidth = null;
                items[i].width = StyleVars.BOARD_CONTROL_BUTTON_WIDTH;
            }
            else
            {
                items[i].width = null; // the percent layout bypasses the setter, so a stale width would make the next identical one a no-op
                items[i].percentWidth = 100 * slots[i] / totalSlots;
            }
        }
    }

    // inside the tray's border, only the corners at the group's two ends are rounded
    private function roundSegmentEnds(vertical:Bool):Void
    {
        var radius:Float = StyleVars.BOARD_CONTROL_BUTTON_RADIUS - 1;
        var first:Box = chameleonModeButtons[0];
        var last:Box = chameleonModeButtons[chameleonModeButtons.length - 1];

        first.customStyle.borderRadiusTopLeft = radius;
        first.customStyle.borderRadiusTopRight = vertical ? radius : 0;
        first.customStyle.borderRadiusBottomLeft = vertical ? 0 : radius;
        first.customStyle.borderRadiusBottomRight = 0;

        last.customStyle.borderRadiusTopLeft = 0;
        last.customStyle.borderRadiusTopRight = vertical ? 0 : radius;
        last.customStyle.borderRadiusBottomLeft = vertical ? radius : 0;
        last.customStyle.borderRadiusBottomRight = radius;

        first.invalidateComponentStyle();
        last.invalidateComponentStyle();
    }

    private static function chameleonModeName(mode:ChameleonMode):String
    {
        return switch mode {
            case Ask: "ask_aura";
            case AutoApprove: "approve_aura";
            case AutoDecline: "decline_aura";
        }
    }

    // `tooltipKey` is relative to `intellector.board.controls`
    private static function createButton(content:Component, tooltipKey:Null<String>, onSelect:Void->Void, styleClass:StyleClass = BOARD_CONTROL):Box
    {
        var button:Box = new Box();
        button.addClass(styleClass);
        button.height = StyleVars.BOARD_CONTROL_BUTTON_HEIGHT;
        if (styleClass == BOARD_CONTROL)
        {
            button.customStyle.borderRadius = StyleVars.BOARD_CONTROL_BUTTON_RADIUS;
            button.invalidateComponentStyle();
        }
        if (tooltipKey != null)
            button.tooltip = LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.board.controls.$tooltipKey'));

        content.horizontalAlign = "center";
        content.verticalAlign = "center";
        // the button itself is always the event target
        content.element.style.pointerEvents = "none";
        button.addComponent(content);

        button.registerEvent(MouseEvent.CLICK, _ -> onSelect());
        return button;
    }

    // between the default page's sections
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

    private static function controlIcon(name:String):Image
    {
        var image:Image = new Image();
        image.resource = Assets.boardControlIcon(name);
        image.width = StyleVars.BOARD_CONTROL_ICON_SIZE;
        image.height = StyleVars.BOARD_CONTROL_ICON_SIZE;
        image.scaleMode = FIT_INSIDE;
        return image;
    }
}
