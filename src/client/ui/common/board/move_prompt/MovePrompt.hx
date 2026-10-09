package client.ui.common.board.move_prompt;

import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxefolio.ElementShadow;
import haxefolio.Shadow;
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
    The move choices `PieceMoveTool` can't make, as popovers following a hex: a ring of pieces to
    promote or premove-morph into, or a capture's become/stay pair. Callbacks are called once it's
    closed; it's cancelled by its own button, a press outside or Esc.
**/
class MovePrompt
{
    // at the anchor's vertex angles, counterclockwise from the right; the hub sits over the anchor
    private static final RING_SLOTS:Array<RingSlot> = [Piece(Aggressor), Piece(Liberator), Piece(Dominator), Cancel, Piece(Progressor), Piece(Defensor)];

    private final roots:Array<Component>;
    private final place:Void->Void;
    private final onCancelled:Void->Void;

    private var resizeObserver:Dynamic;
    private var scrim:PromptScrim;
    private var geometryChangeHandle:Detachable;
    private var closed:Bool = false;

    /** A ring of the promotion options around `anchor`, the Progressor in the middle **/
    public static function promotion(board:BoardSurface, anchor:HexCoords, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        return pieceRing(board, anchor, Progressor, color, [Aggressor, Liberator, Dominator, Defensor], onChosen, onCancelled);
    }

    /** A ring of the kinds a premoved `movingKind` could morph into on capture, its own included **/
    public static function premoveChameleon(board:BoardSurface, anchor:HexCoords, movingKind:PieceKind, color:PieceColor, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        return pieceRing(board, anchor, movingKind, color, [Aggressor, Liberator, Dominator, Progressor, Defensor], onChosen, onCancelled);
    }

    private static function pieceRing(board:BoardSurface, anchor:HexCoords, movingKind:PieceKind, color:PieceColor, options:Array<PieceKind>, onChosen:PieceKind->Void, onCancelled:Void->Void):MovePrompt
    {
        var prompt:Null<MovePrompt> = null;

        // by slot; `null` for an empty one
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

        prompt = new MovePrompt(board, roots, StyleVars.MOVE_PROMPT_RING_SHADOW, () -> placeRing(board, anchor, hub, buttons), onCancelled);
        return prompt;
    }

    /** The become/stay pair for `capturingKind` capturing `capturedKind`, beside `anchor` **/
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
        closeButton.addClass(StyleClass.HAXEFOLIO_CLOSE_BUTTON);
        closeButton.verticalAlign = "center";
        // via the style: the close-button class sets its own fixed size
        closeButton.customStyle.width = StyleVars.MOVE_PROMPT_MORPH_CLOSE_SIZE;
        closeButton.customStyle.height = StyleVars.MOVE_PROMPT_MORPH_CLOSE_SIZE;
        closeButton.customStyle.fontSize = StyleVars.MOVE_PROMPT_MORPH_CLOSE_FONT_SIZE;
        closeButton.customStyle.borderRadius = StyleVars.MOVE_PROMPT_MORPH_CLOSE_RADIUS;
        closeButton.invalidateComponentStyle();
        closeButton.onClick = _ -> prompt.cancel();

        var title:Label = new Label();
        title.text = LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.chameleon.title"));
        title.addClass(StyleClass.PROMPT_TITLE);
        title.percentWidth = 100;
        title.verticalAlign = "center";

        var headerRow:HBox = new HBox();
        headerRow.percentWidth = 100;
        headerRow.height = StyleVars.MOVE_PROMPT_MORPH_CLOSE_SIZE;
        headerRow.addComponent(title);
        headerRow.addComponent(closeButton);

        // both in the capturing piece's colour: it's the mover's piece either way
        var become:PromptButton = PromptButton.labelled(
            capturedKind,
            capturingColor,
            LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.become"), pieceName("intellector.board.prompt.become", capturedKind)),
            true,
            StyleVars.MOVE_PROMPT_MORPH_BUTTON_HEIGHT,
            StyleVars.MOVE_PROMPT_MORPH_ART_SLOT_DIAMETER,
            () -> decide(true)
        );
        var stay:PromptButton = PromptButton.labelled(
            capturingKind,
            capturingColor,
            LocaleUtils.resolveText(LocaleUtils.localeBinding("intellector.board.prompt.stay"), pieceName("intellector.board.prompt.stay", capturingKind)),
            false,
            StyleVars.MOVE_PROMPT_MORPH_BUTTON_HEIGHT,
            StyleVars.MOVE_PROMPT_MORPH_ART_SLOT_DIAMETER,
            () -> decide(false)
        );

        var popover:VBox = new VBox();
        popover.addClass(StyleClass.PROMPT_POPOVER);
        popover.width = StyleVars.MOVE_PROMPT_MORPH_POPOVER_WIDTH;
        popover.addComponent(headerRow);
        popover.addComponent(become);
        popover.addComponent(stay);

        prompt = new MovePrompt(board, [popover], StyleVars.MOVE_PROMPT_POPOVER_SHADOW, () -> placeMorphPopover(board, anchor, popover), onCancelled);
        return prompt;
    }

    /** Takes the prompt off screen without calling back; safe to repeat **/
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

    private function new(board:BoardSurface, roots:Array<Component>, shadow:Shadow, place:Void->Void, onCancelled:Void->Void)
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

        // the board rescales with its container; the popover's height is known only after layout
        resizeObserver = js.Syntax.code("new ResizeObserver({0})", onViewportChanged);
        resizeObserver.observe(board.element);
        for (root in roots)
            resizeObserver.observe(root.element);

        // a flip or coordinates mode change moves the anchor without resizing
        geometryChangeHandle = board.onGeometryChanged.subscribe(place);

        Browser.window.addEventListener("scroll", onViewportChanged, true);
        Browser.window.addEventListener("resize", onViewportChanged);

        // deferred, or the press that opened the prompt would cancel it in its bubble phase
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

    // untyped: shared by the ResizeObserver and the window's scroll/resize events
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

        var diameter:Float = Math.max(StyleVars.MOVE_PROMPT_RING_MINIMUM_DIAMETER, Math.round(hexHeight * StyleVars.MOVE_PROMPT_RING_DIAMETER_SHARE));
        var half:Float = diameter / 2;

        // buttons clear each other and the hex's corners (a side length from its centre) by the gap
        var hexSideLength:Float = hexHeight / Math.sqrt(3);
        var radius:Float = Math.max(diameter + StyleVars.MOVE_PROMPT_RING_GAP, hexSideLength + half + StyleVars.MOVE_PROMPT_RING_GAP);

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

        // near a viewport edge the whole ring slides inward as a unit
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
        var height:Float = measuredHeight > 0 ? measuredHeight : StyleVars.MOVE_PROMPT_MORPH_ESTIMATED_HEIGHT;

        /*
            Toward the board's centre: below an upper-half hex, above a lower-half one, reaching
            further inward the closer the hex is to an edge.
        */
        var width:Float = Math.min(StyleVars.MOVE_PROMPT_MORPH_POPOVER_WIDTH, Browser.window.innerWidth - 2 * StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN);
        popover.width = width;

        var reach:Float = Math.max(0, width / 2 - hexHeight / Math.sqrt(3));
        var left:Float = center.x - board.horizontalPosition(anchor) * reach - width / 2;

        var top:Float = board.isInLowerHalf(anchor)
            ? center.y - hexHeight / 2 - StyleVars.MOVE_PROMPT_MORPH_ANCHOR_GAP - height
            : center.y + hexHeight / 2 + StyleVars.MOVE_PROMPT_MORPH_ANCHOR_GAP;

        // only to fit on screen
        left += shiftIntoViewport(left, left + width, Browser.window.innerWidth);
        top += shiftIntoViewport(top, top + height, Browser.window.innerHeight);

        moveTo(popover, left, top);
    }

    // how far [low, high] must move to fit within the viewport's margins; the low edge wins if it can't
    private static function shiftIntoViewport(low:Float, high:Float, viewportSize:Float):Float
    {
        if (low < StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN)
            return StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN - low;

        if (high > viewportSize - StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN)
            return Math.max(viewportSize - StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN - high, StyleVars.MOVE_PROMPT_VIEWPORT_MARGIN - low);

        return 0;
    }

    // takes viewport pixels; components are positioned in HaxeUI's scale-divided space
    private static function moveTo(component:Component, clientX:Float, clientY:Float):Void
    {
        component.left = clientX / Toolkit.scaleX;
        component.top = clientY / Toolkit.scaleY;
    }

    // in the grammatical case `templateKey.case` asks for
    private static function pieceName(templateKey:String, kind:PieceKind):String
    {
        var grammaticalCase:String = LocaleUtils.resolveText(LocaleUtils.localeBinding('$templateKey.case'));
        return LocaleUtils.resolveText(GroupedLocaleResolvers.pieceName(kind, grammaticalCase));
    }
}
