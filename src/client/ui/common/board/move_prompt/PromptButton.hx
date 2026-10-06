package client.ui.common.board.move_prompt;

import client.ui.Assets;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/**
    A move prompt button: piece art in a circular slot, optionally labelled, or a bare cross for
    cancelling. Hover and press states are driven here, as `:hover`/`:down` would lose the events to
    the children.
**/
class PromptButton extends Box
{
    private final onSelect:Null<Void->Void>;

    private var slot:Null<Box> = null;
    private var art:Null<Image> = null;
    private var artAspectRatio:Float = 1;
    private var cross:Null<Label> = null;

    /** A ring's art-only button, sized by `setDiameter`; `stay` styles it as keeping the piece **/
    public static function round(kind:PieceKind, color:PieceColor, stay:Bool, onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = roundArt(kind, color, onSelect);
        if (stay)
            button.addClass(StyleClass.PROMPT_BUTTON_STAY);
        return button;
    }

    /** The non-button disc at a ring's centre, showing the moving piece; sized by `setDiameter` **/
    public static function hub(kind:PieceKind, color:PieceColor):PromptButton
    {
        var hub:PromptButton = roundArt(kind, color, null);
        hub.addClass(StyleClass.PROMPT_HUB);
        return hub;
    }

    private static function roundArt(kind:PieceKind, color:PieceColor, onSelect:Null<Void->Void>):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass(StyleClass.PROMPT_BUTTON_ROUND);

        var slot:Box = new Box();
        slot.addClass(StyleClass.PROMPT_ART_SLOT);
        slot.horizontalAlign = "center";
        slot.verticalAlign = "center";
        // so entering the art doesn't read as leaving the button
        slot.element.style.pointerEvents = "none";

        var art:Image = createArt(kind, color);
        slot.addComponent(art);
        button.addComponent(slot);

        button.slot = slot;
        button.art = art;
        button.artAspectRatio = Assets.pieceAspectRatio(kind);

        return button;
    }

    /** A ring's cancel button, a cross; sized by `setDiameter` **/
    public static function cancelRound(onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass(StyleClass.PROMPT_BUTTON_ROUND);
        button.addClass(StyleClass.PROMPT_BUTTON_CANCEL);

        var cross:Label = new Label();
        cross.text = "✕";
        cross.addClass(StyleClass.PROMPT_CROSS);
        cross.horizontalAlign = "center";
        cross.verticalAlign = "center";
        cross.element.style.pointerEvents = "none";
        button.addComponent(cross);

        button.cross = cross;

        return button;
    }

    /** A full-width button with art and `label`, at least `minimumHeight` px tall **/
    public static function labelled(kind:PieceKind, color:PieceColor, label:String, emphasised:Bool, minimumHeight:Int, artSlotDiameter:Int, onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass(StyleClass.PROMPT_BUTTON_LABELLED);
        button.addClass(emphasised ? StyleClass.PROMPT_BUTTON_EMPHASISED : StyleClass.PROMPT_BUTTON_NEUTRAL);
        button.percentWidth = 100;
        button.customStyle.minHeight = minimumHeight;

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.verticalAlign = "center";
        row.horizontalSpacing = StyleVars.MOVE_PROMPT_LABELLED_BUTTON_SPACING;
        // inherited by the subtree, so the button is always the event target
        row.element.style.pointerEvents = "none";

        var slot:Box = new Box();
        slot.addClass(StyleClass.PROMPT_ART_SLOT);
        slot.verticalAlign = "center";
        var art:Image = createArt(kind, color);
        slot.addComponent(art);
        row.addComponent(slot);

        button.slot = slot;
        button.art = art;
        button.artAspectRatio = Assets.pieceAspectRatio(kind);
        button.fitSlot(artSlotDiameter);

        var text:Label = new Label();
        text.text = label;
        text.addClass(StyleClass.PROMPT_BUTTON_LABEL);
        text.percentWidth = 100;
        text.verticalAlign = "center";
        row.addComponent(text);

        button.addComponent(row);

        return button;
    }

    /** Resizes a round button (`round`/`cancelRound`) to `diameter` px, art and all **/
    public function setDiameter(diameter:Float):Void
    {
        width = diameter;
        height = diameter;
        setRadius(this, diameter / 2);

        if (slot != null)
            fitSlot(Math.round(diameter * StyleVars.MOVE_PROMPT_SLOT_SHARE));

        if (cross != null)
        {
            cross.customStyle.fontSize = Math.round(diameter * StyleVars.MOVE_PROMPT_CROSS_SHARE);
            cross.invalidateComponentStyle();
        }
    }

    // a `null` `onSelect` makes a static disc rather than a button
    private function new(onSelect:Null<Void->Void>)
    {
        super();

        this.onSelect = onSelect;
        addClass(StyleClass.PROMPT_BUTTON);

        if (onSelect == null)
            return;

        element.style.cursor = "pointer";

        registerEvent(MouseEvent.MOUSE_OVER, _ -> addClass(StyleClass.PROMPT_BUTTON_ACTIVE));
        registerEvent(MouseEvent.MOUSE_OUT, _ -> {
            removeClass(StyleClass.PROMPT_BUTTON_ACTIVE);
            removeClass(StyleClass.PROMPT_BUTTON_PRESSED);
        });
        registerEvent(MouseEvent.MOUSE_DOWN, _ -> addClass(StyleClass.PROMPT_BUTTON_PRESSED));
        registerEvent(MouseEvent.MOUSE_UP, _ -> removeClass(StyleClass.PROMPT_BUTTON_PRESSED));
        registerEvent(MouseEvent.CLICK, _ -> onSelect());
    }

    private function fitSlot(slotDiameter:Float):Void
    {
        slot.width = slotDiameter;
        slot.height = slotDiameter;
        setRadius(slot, slotDiameter / 2);

        // smaller than the slot, so no piece touches its rim
        var artBox:Float = Math.round(slotDiameter * StyleVars.MOVE_PROMPT_ART_SHARE);
        art.width = artAspectRatio >= 1 ? artBox : artBox * artAspectRatio;
        art.height = artAspectRatio >= 1 ? artBox / artAspectRatio : artBox;
    }

    // HaxeUI doesn't resolve a percentage border-radius
    private static function setRadius(component:Box, radius:Float):Void
    {
        component.customStyle.borderRadius = radius;
        component.invalidateComponentStyle();
    }

    private static function createArt(kind:PieceKind, color:PieceColor):Image
    {
        var art:Image = new Image();
        art.resource = Assets.pieceImage(kind, color);
        art.horizontalAlign = "center";
        art.verticalAlign = "center";
        return art;
    }
}
