package client.ui.common.board.move_prompt;

import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.ElementShadow;
import haxefolio.LocaleUtils;
import intellectorboard.primitives.hex.HexCoords;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;
import js.Browser;
import js.html.KeyboardEvent;
import js.html.Node;
import js.html.PointerEvent;

using Lambda;

/**
    The two move-detail choices `MoveInteractionController` can't resolve on its own, presented as
    popovers anchored to a board hex (knowledge/plans/promotion-and-morph-popovers.md): which piece
    a Progressor promotes into (a fan of round buttons), and whether a capturing piece morphs into
    the type it captured (two labelled buttons).

    Both are non-modal - the board stays visible - and can be cancelled: by their own cancel
    button (the fan's last button, the morph popover's close button), by a press anywhere outside
    them, or by Esc. Cancelling only closes the popover and calls `onCancelled`; the owner also
    closes it, via `close`, when the position changes underneath it. Follows the anchor hex while
    the board rescales or the page scrolls.
**/
class MovePrompt
{
    private static inline final PROMOTION_SHADOW:String = "0 4px 14px rgba(42, 33, 26, 0.18)";
    private static inline final POPOVER_SHADOW:String = "0 8px 28px rgba(42, 33, 26, 0.16)";

    private static inline final VIEWPORT_MARGIN:Float = 8;

    // Four promotion options plus the cancel button, on an arc centred on the anchor hex.
    private static inline final FAN_SLOT_COUNT:Int = 5;
    private static inline final FAN_GAP:Float = 6;
    private static inline final FAN_MINIMUM_DIAMETER:Float = 44;

    // A button's diameter as a share of the hex's on-screen height: its radius is close to the hex's inner radius.
    private static inline final FAN_DIAMETER_SHARE:Float = 0.9;

    /*
        The angle between neighbouring buttons. Over an outer file (a, i) the arc is squeezed into a
        quarter of a circle, running from straight below/above the hex to straight beside it, toward the
        board's centre; over every other file it is wider, symmetric about the vertical through the hex.
        Each arc's radius is whatever keeps its own neighbours apart, so the quarter circle is the larger one.
    */
    private static final FAN_STEP:Float = 40 * Math.PI / 180;
    private static final FAN_EDGE_STEP:Float = 90 / (FAN_SLOT_COUNT - 1) * Math.PI / 180;
    private static inline final FAN_EDGE_TILT_DEGREES:Float = 45;

    // The most the axis may turn to make the fan fit the viewport, over the files that don't turn by default.
    private static inline final FAN_MAXIMUM_TILT_DEGREES:Float = 60;

    // Fixed left-to-right order, not whatever order the rules happen to list the options in.
    private static final PROMOTION_OPTIONS:Array<PieceKind> = [Aggressor, Defensor, Liberator, Dominator];

    private static inline final MORPH_POPOVER_WIDTH:Int = 390;
    private static inline final MORPH_POPOVER_SPACING:Int = 12;
    private static inline final MORPH_BUTTON_HEIGHT:Int = 84;
    private static inline final MORPH_ART_SLOT_DIAMETER:Int = 60;
    private static inline final MORPH_CLOSE_SIZE:Int = 42;
    private static inline final MORPH_CLOSE_FONT_SIZE:Int = 21;
    private static inline final MORPH_CLOSE_RADIUS:Int = 6;
    private static inline final MORPH_ANCHOR_GAP:Float = 12;

    // Before the popover has been laid out for the first time and its real height can be measured.
    private static inline final MORPH_ESTIMATED_HEIGHT:Float = 264;

    private final roots:Array<Component>;
    private final place:Void->Void;
    private final onCancelled:Void->Void;

    private var resizeObserver:Dynamic;
    private var closed:Bool = false;

    /**
        A fan of the four promotion options, in `color`, and a cancel button, on an arc around the
        hex `anchor` that opens toward the board's interior. `onChosen` is called after the fan is
        closed; `onCancelled` after it is closed by cancelling.
    **/
    public static function promotion(board:BoardSurface, anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        var prompt:Null<MovePrompt> = null;
        var buttons:Array<PromptButton> = [];

        for (kind in PROMOTION_OPTIONS)
        {
            buttons.push(PromptButton.round(kind, color, () -> {
                prompt.close();
                onChosen(kind);
            }));
        }
        buttons.push(PromptButton.cancelRound(() -> prompt.cancel()));

        prompt = new MovePrompt(board, [for (button in buttons) button], PROMOTION_SHADOW, () -> placeFan(board, anchor, buttons), onCancelled);
        return prompt;
    }

    /**
        The "become the captured piece / stay as is" pair for `capturingKind` (of `capturingColor`)
        having captured `capturedKind`, next to the hex `anchor`, on the side facing the board's
        centre. `onDecided` is called with whether to morph, after the popover is closed;
        `onCancelled` after it is closed by cancelling.
    **/
    public static function captureMorph(board:BoardSurface, anchor:HexCoords, capturingKind:PieceKind, capturingColor:PieceColor, capturedKind:PieceKind, onDecided:Bool->Void, onCancelled:Void->Void):MovePrompt
    {
        var prompt:Null<MovePrompt> = null;

        function decide(morph:Bool):Void
        {
            prompt.close();
            onDecided(morph);
        }

        var closeButton:Button = new Button();
        closeButton.text = "✕";
        closeButton.addClass("haxefolio-close-button");
        closeButton.verticalAlign = "center";
        // Through the style, not width/height: the framework's close-button class sets its own fixed size.
        closeButton.customStyle.width = MORPH_CLOSE_SIZE;
        closeButton.customStyle.height = MORPH_CLOSE_SIZE;
        closeButton.customStyle.fontSize = MORPH_CLOSE_FONT_SIZE;
        closeButton.customStyle.borderRadius = MORPH_CLOSE_RADIUS;
        closeButton.invalidateComponentStyle();
        closeButton.onClick = _ -> prompt.cancel();

        var title:Label = new Label();
        title.text = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.chameleon.title"));
        title.addClass("intellector-prompt-title");
        title.percentWidth = 100;
        title.verticalAlign = "center";

        var headerRow:HBox = new HBox();
        headerRow.percentWidth = 100;
        headerRow.height = MORPH_CLOSE_SIZE;
        headerRow.addComponent(title);
        headerRow.addComponent(closeButton);

        // Both keep the capturing piece's colour: it's the mover's own piece that changes type or stays.
        var become:PromptButton = PromptButton.labelled(
            capturedKind,
            capturingColor,
            LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.become"), pieceName("intellector.board.prompt.become", capturedKind)),
            true,
            MORPH_BUTTON_HEIGHT,
            MORPH_ART_SLOT_DIAMETER,
            () -> decide(true)
        );
        var stay:PromptButton = PromptButton.labelled(
            capturingKind,
            capturingColor,
            LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.stay"), pieceName("intellector.board.prompt.stay", capturingKind)),
            false,
            MORPH_BUTTON_HEIGHT,
            MORPH_ART_SLOT_DIAMETER,
            () -> decide(false)
        );

        var popover:VBox = new VBox();
        popover.addClass("intellector-prompt-popover");
        popover.width = MORPH_POPOVER_WIDTH;
        popover.verticalSpacing = MORPH_POPOVER_SPACING;
        popover.addComponent(headerRow);
        popover.addComponent(become);
        popover.addComponent(stay);

        prompt = new MovePrompt(board, [popover], POPOVER_SHADOW, () -> placeMorphPopover(board, anchor, popover), onCancelled);
        return prompt;
    }

    /**
        Takes the popover off screen. Safe to call more than once; never calls either callback.
    **/
    public function close():Void
    {
        if (closed)
            return;

        closed = true;

        resizeObserver.disconnect();
        Browser.window.removeEventListener("scroll", onViewportChanged, true);
        Browser.window.removeEventListener("resize", onViewportChanged);
        Browser.window.removeEventListener("pointerdown", onPointerDown);
        Browser.document.removeEventListener("keydown", onKeyDown, true);

        for (root in roots)
            Screen.instance.removeComponent(root, true);
    }

    private function new(board:BoardSurface, roots:Array<Component>, shadow:String, place:Void->Void, onCancelled:Void->Void)
    {
        this.roots = roots;
        this.place = place;
        this.onCancelled = onCancelled;

        for (root in roots)
        {
            Screen.instance.addComponent(root);
            ElementShadow.apply(root.element, shadow);
        }

        place();

        // The board rescales with its container, and the popover's own height is only known after layout.
        resizeObserver = js.Syntax.code("new ResizeObserver({0})", onViewportChanged);
        resizeObserver.observe(board.element);
        for (root in roots)
            resizeObserver.observe(root.element);

        Browser.window.addEventListener("scroll", onViewportChanged, true);
        Browser.window.addEventListener("resize", onViewportChanged);

        /*
            Bubbling phase, registered after the controller's own listener: the press that cancels is
            first seen (and ignored) by the controller as one made while a choice is pending, so it
            can't also start a new gesture on the board.
        */
        Browser.window.addEventListener("pointerdown", onPointerDown);
        Browser.document.addEventListener("keydown", onKeyDown, true);
    }

    private function cancel():Void
    {
        if (closed)
            return;

        close();
        onCancelled();
    }

    // Shared by the ResizeObserver and the window's scroll/resize events, hence the untyped argument.
    private function onViewportChanged(_:Dynamic):Void
    {
        if (!closed)
            place();
    }

    private function onPointerDown(e:PointerEvent):Void
    {
        var target:Node = cast e.target;
        if (!roots.exists(root -> root.element.contains(target)))
            cancel();
    }

    private function onKeyDown(e:KeyboardEvent):Void
    {
        if (e.key != "Escape")
            return;

        e.preventDefault();
        cancel();
    }

    private static function placeFan(board:BoardSurface, anchor:HexCoords, buttons:Array<PromptButton>):Void
    {
        var center = board.hexClientCenter(anchor);
        var hexHeight:Float = board.hexClientHeight();

        var diameter:Float = Math.max(FAN_MINIMUM_DIAMETER, Math.round(hexHeight * FAN_DIAMETER_SHARE));
        for (button in buttons)
            button.setDiameter(diameter);

        var horizontalPosition:Float = board.horizontalPosition(anchor);
        var isEdgeFile:Bool = Math.abs(horizontalPosition) > 0.99;
        var step:Float = isEdgeFile ? FAN_EDGE_STEP : FAN_STEP;

        // Far enough that neighbouring buttons clear each other by FAN_GAP, and that the ones
        // around the side clear the hex itself (its corners, a side length from the centre).
        var hexSideLength:Float = hexHeight / Math.sqrt(3);
        var radius:Float = Math.max(
            (diameter + FAN_GAP) / (2 * Math.sin(step / 2)),
            hexSideLength + diameter / 2 + FAN_GAP
        );

        // Toward the board's interior: a hex in the lower half (Black's promotion rank, on a
        // White-oriented board) mirrors the fan upward.
        var direction:Float = board.isInLowerHalf(anchor) ? -1 : 1;

        // The axis leans toward the board's centre: fixed for an outer file, only as far as needed to fit elsewhere.
        var lean:Float = horizontalPosition < 0 ? 1 : (horizontalPosition > 0 ? -1 : (center.x < Browser.window.innerWidth / 2 ? 1 : -1));
        var tiltDegrees:Float = isEdgeFile ? FAN_EDGE_TILT_DEGREES : 0;

        var half:Float = diameter / 2;
        var centers:Array<{x:Float, y:Float}> = fanCenters(center, radius, step, direction, lean * tiltDegrees);
        while (!isEdgeFile && tiltDegrees < FAN_MAXIMUM_TILT_DEGREES && !fitsHorizontally(centers, half))
        {
            tiltDegrees += 1;
            centers = fanCenters(center, radius, step, direction, lean * tiltDegrees);
        }

        var minX:Float = Math.POSITIVE_INFINITY;
        var maxX:Float = Math.NEGATIVE_INFINITY;
        var minY:Float = Math.POSITIVE_INFINITY;
        var maxY:Float = Math.NEGATIVE_INFINITY;
        for (buttonCenter in centers)
        {
            minX = Math.min(minX, buttonCenter.x - half);
            maxX = Math.max(maxX, buttonCenter.x + half);
            minY = Math.min(minY, buttonCenter.y - half);
            maxY = Math.max(maxY, buttonCenter.y + half);
        }

        // Whatever turning couldn't fix: one shift for the whole fan, so it slides as a unit.
        var shiftX:Float = shiftIntoViewport(minX, maxX, Browser.window.innerWidth);
        var shiftY:Float = shiftIntoViewport(minY, maxY, Browser.window.innerHeight);

        for (i in 0...buttons.length)
            moveTo(buttons[i], centers[i].x - half + shiftX, centers[i].y - half + shiftY);
    }

    /*
        The button centres, left to right, around `center` on a circle of `radius`, `step`
        apart and symmetric about the fan's axis. The axis points down (or up, for direction -1),
        turned `tiltDegrees` toward +x - the rotation is done by positioning, not by rotating the buttons.
    */
    private static function fanCenters(center:{x:Float, y:Float}, radius:Float, step:Float, direction:Float, tiltDegrees:Float):Array<{x:Float, y:Float}>
    {
        var tilt:Float = tiltDegrees * Math.PI / 180;
        var axisX:Float = Math.sin(tilt);
        var axisY:Float = direction * Math.cos(tilt);
        var sideX:Float = Math.cos(tilt);
        var sideY:Float = -direction * Math.sin(tilt);

        return [
            for (slot in 0...FAN_SLOT_COUNT)
            {
                var angle:Float = (slot - (FAN_SLOT_COUNT - 1) / 2) * step;
                {
                    x: center.x + radius * (Math.cos(angle) * axisX + Math.sin(angle) * sideX),
                    y: center.y + radius * (Math.cos(angle) * axisY + Math.sin(angle) * sideY)
                }
            }
        ];
    }

    private static function fitsHorizontally(centers:Array<{x:Float, y:Float}>, half:Float):Bool
    {
        return centers.foreach(buttonCenter -> buttonCenter.x - half >= VIEWPORT_MARGIN && buttonCenter.x + half <= Browser.window.innerWidth - VIEWPORT_MARGIN);
    }

    private static function placeMorphPopover(board:BoardSurface, anchor:HexCoords, popover:VBox):Void
    {
        var center = board.hexClientCenter(anchor);
        var hexHeight:Float = board.hexClientHeight();

        var measuredHeight:Float = popover.element.getBoundingClientRect().height;
        var height:Float = measuredHeight > 0 ? measuredHeight : MORPH_ESTIMATED_HEIGHT;

        // Toward the board's centre, both ways: below an upper-half hex and above a lower-half one; and
        // sideways so that, the closer the hex is to an edge, the more the popover reaches inward
        // (flush with the hex's outer corner at the very edge, centred on the hex in the middle).
        var width:Float = Math.min(MORPH_POPOVER_WIDTH, Browser.window.innerWidth - 2 * VIEWPORT_MARGIN);
        popover.width = width;

        var reach:Float = Math.max(0, width / 2 - hexHeight / Math.sqrt(3));
        var left:Float = center.x - board.horizontalPosition(anchor) * reach - width / 2;

        var top:Float = board.isInLowerHalf(anchor)
            ? center.y - hexHeight / 2 - MORPH_ANCHOR_GAP - height
            : center.y + hexHeight / 2 + MORPH_ANCHOR_GAP;

        // Only to make sure it fits on screen.
        left += shiftIntoViewport(left, left + width, Browser.window.innerWidth);
        top += shiftIntoViewport(top, top + height, Browser.window.innerHeight);

        moveTo(popover, left, top);
    }

    /*
        How far a span [low, high] must move along one axis to lie within the viewport minus its
        margin (low edge wins if it can't fit at all).
    */
    private static function shiftIntoViewport(low:Float, high:Float, viewportSize:Float):Float
    {
        if (low < VIEWPORT_MARGIN)
            return VIEWPORT_MARGIN - low;

        if (high > viewportSize - VIEWPORT_MARGIN)
            return Math.max(viewportSize - VIEWPORT_MARGIN - high, VIEWPORT_MARGIN - low);

        return 0;
    }

    // Takes viewport pixels; components are positioned in HaxeUI's own (scale-divided) space.
    private static function moveTo(component:Component, clientX:Float, clientY:Float):Void
    {
        component.left = clientX / Toolkit.scaleX;
        component.top = clientY / Toolkit.scaleY;
    }

    /*
        The piece's name in whichever grammatical case the template `templateKey` asks for (its
        `.case` key), which differs between languages.
    */
    private static function pieceName(templateKey:String, kind:PieceKind):String
    {
        var grammaticalCase:String = LocaleUtils.resolveText(LocaleUtils.localeBinding('$templateKey.case'));
        return LocaleUtils.resolveText(LocaleUtils.localeBinding('intellector.piece.${Std.string(kind).toLowerCase()}.$grammaticalCase'));
    }
}
