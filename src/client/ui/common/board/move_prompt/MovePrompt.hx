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
import morestd.Detachable;

using Lambda;

private enum RingSlot
{
    Piece(kind:PieceKind);
    Cancel;
}

/**
    The two move-detail choices `PieceMoveTool` can't resolve on its own, presented as
    popovers anchored to a board hex (knowledge/plans/promotion-and-morph-popovers.md): which piece
    a Progressor promotes into, or a premoved piece morphs into (a ring of round buttons around the
    moving piece), and whether a capturing piece morphs into the type it captured (two labelled
    buttons).

    Both keep the board visible under a very light scrim, and can be cancelled: by their own cancel
    button (the ring's cross, the morph popover's close button), by a press anywhere outside
    them (which lands on the scrim, so nothing underneath reacts to it), or by Esc. Cancelling only closes the popover and calls `onCancelled`; the owner also
    closes it, via `close`, when the position changes underneath it. Follows the anchor hex while
    the board rescales, flips or the page scrolls.
**/
class MovePrompt
{
    private static inline final RING_SHADOW:String = "0 4px 14px rgba(42, 33, 26, 0.18)";
    private static inline final POPOVER_SHADOW:String = "0 8px 28px rgba(42, 33, 26, 0.16)";

    private static inline final VIEWPORT_MARGIN:Float = 8;

    /*
        A piece ring: six slots around the anchor hex, at its vertex angles (counterclockwise from
        the right one), the same for every anchor and both ring prompts. The hub sits over the anchor.
    */
    private static final RING_SLOTS:Array<RingSlot> = [Piece(Aggressor), Piece(Liberator), Piece(Dominator), Cancel, Piece(Progressor), Piece(Defensor)];
    private static inline final RING_GAP:Float = 6;
    private static inline final RING_MINIMUM_DIAMETER:Float = 44;

    // A button's diameter as a share of the hex's on-screen height: its radius is close to the hex's inner radius.
    private static inline final RING_DIAMETER_SHARE:Float = 0.9;

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
    private var scrim:PromptScrim;
    private var geometryChangeHandle:Detachable;
    private var closed:Bool = false;

    /**
        A ring of the four promotion options, in `color`, and a cancel button around the hex
        `anchor`, with the promoting Progressor in the middle. `onChosen` is called after the ring
        is closed; `onCancelled` after it is closed by cancelling.
    **/
    public static function promotion(board:BoardSurface, anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        return pieceRing(board, anchor, Progressor, color, [Aggressor, Liberator, Dominator, Defensor], onChosen, onCancelled);
    }

    /**
        A ring of the five kinds a premoved `movingKind` (of `color`) could morph into on capture -
        its own kind among them, styled as staying as is - and a cancel button, around the hex
        `anchor`. `onChosen` is called after the ring is closed; `onCancelled` after it is closed
        by cancelling.
    **/
    public static function premoveChameleon(board:BoardSurface, anchor:HexCoords, movingKind:PieceKind, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        return pieceRing(board, anchor, movingKind, color, [Aggressor, Liberator, Dominator, Progressor, Defensor], onChosen, onCancelled);
    }

    private static function pieceRing(board:BoardSurface, anchor:HexCoords, movingKind:PieceKind, color:PieceColor, options:Array<PieceKind>, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        var prompt:Null<MovePrompt> = null;

        // By slot; null for a slot left empty.
        var buttons:Array<Null<PromptButton>> = [
            for (slot in RING_SLOTS)
            {
                switch slot {
                    case Cancel:
                        PromptButton.cancelRound(() -> prompt.cancel());
                    case Piece(kind) if (options.contains(kind)):
                        PromptButton.round(kind, color, kind == movingKind, () -> {
                            prompt.close();
                            onChosen(kind);
                        });
                    case Piece(_):
                        null;
                }
            }
        ];
        var hub:PromptButton = PromptButton.hub(movingKind, color);

        var roots:Array<Component> = [hub];
        for (button in buttons)
            if (button != null)
                roots.push(button);

        prompt = new MovePrompt(board, roots, RING_SHADOW, () -> placeRing(board, anchor, hub, buttons), onCancelled);
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
        geometryChangeHandle.detach();
        Browser.window.removeEventListener("scroll", onViewportChanged, true);
        Browser.window.removeEventListener("resize", onViewportChanged);
        Browser.window.removeEventListener("pointerdown", onPointerDown);
        Browser.document.removeEventListener("keydown", onKeyDown, true);

        scrim.remove();
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
        scrim = new PromptScrim(roots[0].element);

        place();

        // The board rescales with its container, and the popover's own height is only known after layout.
        resizeObserver = js.Syntax.code("new ResizeObserver({0})", onViewportChanged);
        resizeObserver.observe(board.element);
        for (root in roots)
            resizeObserver.observe(root.element);

        // A flip or a coordinates mode change moves the anchor without resizing anything.
        geometryChangeHandle = board.onGeometryChanged.subscribe(place);

        Browser.window.addEventListener("scroll", onViewportChanged, true);
        Browser.window.addEventListener("resize", onViewportChanged);

        /*
            Only once the event that opened the prompt is over: a prompt opened by a press would
            otherwise receive that same press in its bubble phase and cancel itself at once.
        */
        Browser.window.setTimeout(listenForOutsidePresses, 0);
        Browser.document.addEventListener("keydown", onKeyDown, true);
    }

    private function listenForOutsidePresses():Void
    {
        if (!closed)
            Browser.window.addEventListener("pointerdown", onPointerDown);
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

    private static function placeRing(board:BoardSurface, anchor:HexCoords, hub:PromptButton, buttons:Array<Null<PromptButton>>):Void
    {
        var center:{x:Float, y:Float} = board.hexClientCenter(anchor);
        var hexHeight:Float = board.hexClientHeight();

        var diameter:Float = Math.max(RING_MINIMUM_DIAMETER, Math.round(hexHeight * RING_DIAMETER_SHARE));
        var half:Float = diameter / 2;

        // Far enough that neighbouring buttons clear each other by RING_GAP, and clear the hex itself (its corners, a side length from the centre).
        var hexSideLength:Float = hexHeight / Math.sqrt(3);
        var radius:Float = Math.max(diameter + RING_GAP, hexSideLength + half + RING_GAP);

        var items:Array<{button:PromptButton, x:Float, y:Float}> = [{button: hub, x: center.x, y: center.y}];
        for (i in 0...buttons.length)
        {
            if (buttons[i] == null)
                continue;

            var angle:Float = i * Math.PI / 3;
            items.push({button: buttons[i], x: center.x + radius * Math.cos(angle), y: center.y - radius * Math.sin(angle)});
        }

        var minX:Float = center.x - radius - half;
        var maxX:Float = center.x + radius + half;
        var minY:Float = center.y - radius - half;
        var maxY:Float = center.y + radius + half;

        // Near a viewport edge the whole ring, hub included, slides inward as a unit.
        var shiftX:Float = shiftIntoViewport(minX, maxX, Browser.window.innerWidth);
        var shiftY:Float = shiftIntoViewport(minY, maxY, Browser.window.innerHeight);

        for (item in items)
        {
            item.button.setDiameter(diameter);
            moveTo(item.button, item.x - half + shiftX, item.y - half + shiftY);
        }
    }

    private static function placeMorphPopover(board:BoardSurface, anchor:HexCoords, popover:VBox):Void
    {
        var center:{x:Float, y:Float} = board.hexClientCenter(anchor);
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
