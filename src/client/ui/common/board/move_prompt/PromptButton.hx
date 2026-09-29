package client.ui.common.board.move_prompt;

import client.Assets;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.events.MouseEvent;
import intellectorboard.primitives.piece.PieceColor;
import intellectorboard.primitives.piece.PieceKind;

/**
    A button of a move prompt popover: piece art in a circular slot, optionally followed by a
    label - or a bare cross, for cancelling. Pointer states only (hover, pressed), driven here
    rather than by `:hover`/`:down` selectors since the button is a composite whose children would
    otherwise steal the events. Styled by the `intellector-prompt-*` classes in main.css.
**/
class PromptButton extends Box
{
    // Share of a round button's diameter taken by the art slot, and of the slot by the art itself.
    private static inline final SLOT_SHARE:Float = 0.72;
    private static inline final ART_SHARE:Float = 0.76;
    private static inline final CROSS_SHARE:Float = 0.4;

    private final onSelect:Void->Void;

    private var slot:Null<Box> = null;
    private var art:Null<Image> = null;
    private var artAspectRatio:Float = 1;
    private var cross:Null<Label> = null;

    /**
        A round, art-only button (the promotion fan's). Its size is set by `setDiameter`.
    **/
    public static function round(kind:PieceKind, color:PieceColor, onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass("intellector-prompt-button-round");

        var slot:Box = new Box();
        slot.addClass("intellector-prompt-art-slot");
        slot.horizontalAlign = "center";
        slot.verticalAlign = "center";
        // Children are never the event target, so entering the art doesn't read as leaving the button.
        slot.element.style.pointerEvents = "none";

        var art:Image = createArt(kind, color);
        slot.addComponent(art);
        button.addComponent(slot);

        button.slot = slot;
        button.art = art;
        button.artAspectRatio = BoardSurface.pieceAspectRatio(kind);

        return button;
    }

    /**
        A round button with a cross in it, for cancelling (the promotion fan's last button). Its
        size is set by `setDiameter`.
    **/
    public static function cancelRound(onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass("intellector-prompt-button-round");
        button.addClass("intellector-prompt-button-cancel");

        var cross:Label = new Label();
        cross.text = "✕";
        cross.addClass("intellector-prompt-cross");
        cross.horizontalAlign = "center";
        cross.verticalAlign = "center";
        cross.element.style.pointerEvents = "none";
        button.addComponent(cross);

        button.cross = cross;

        return button;
    }

    /**
        A full-width button with the art on the left and `label` beside it, at least `minimumHeight`
        px tall (it grows when the label wraps).
    **/
    public static function labelled(kind:PieceKind, color:PieceColor, label:String, emphasised:Bool, minimumHeight:Int, artSlotDiameter:Int, onSelect:Void->Void):PromptButton
    {
        var button:PromptButton = new PromptButton(onSelect);
        button.addClass("intellector-prompt-button-labelled");
        button.addClass(emphasised ? "intellector-prompt-button-emphasised" : "intellector-prompt-button-neutral");
        button.percentWidth = 100;
        button.customStyle.minHeight = minimumHeight;

        var row:HBox = new HBox();
        row.percentWidth = 100;
        row.verticalAlign = "center";
        row.horizontalSpacing = 18;
        // Inherited by the whole subtree, so the button itself is always the event target.
        row.element.style.pointerEvents = "none";

        var slot:Box = new Box();
        slot.addClass("intellector-prompt-art-slot");
        slot.verticalAlign = "center";
        var art:Image = createArt(kind, color);
        slot.addComponent(art);
        row.addComponent(slot);

        button.slot = slot;
        button.art = art;
        button.artAspectRatio = BoardSurface.pieceAspectRatio(kind);
        button.fitSlot(artSlotDiameter);

        var text:Label = new Label();
        text.text = label;
        text.addClass("intellector-prompt-button-label");
        text.percentWidth = 100;
        text.verticalAlign = "center";
        row.addComponent(text);

        button.addComponent(row);

        return button;
    }

    /**
        Resizes a round button (`round`/`cancelRound`) to `diameter` px, art and all.
    **/
    public function setDiameter(diameter:Float):Void
    {
        width = diameter;
        height = diameter;
        setRadius(this, diameter / 2);

        if (slot != null)
            fitSlot(Math.round(diameter * SLOT_SHARE));

        if (cross != null)
        {
            cross.customStyle.fontSize = Math.round(diameter * CROSS_SHARE);
            cross.invalidateComponentStyle();
        }
    }

    private function new(onSelect:Void->Void)
    {
        super();

        this.onSelect = onSelect;
        addClass("intellector-prompt-button");
        element.style.cursor = "pointer";

        registerEvent(MouseEvent.MOUSE_OVER, _ -> addClass("intellector-prompt-button-active"));
        registerEvent(MouseEvent.MOUSE_OUT, _ -> {
            removeClass("intellector-prompt-button-active");
            removeClass("intellector-prompt-button-pressed");
        });
        registerEvent(MouseEvent.MOUSE_DOWN, _ -> addClass("intellector-prompt-button-pressed"));
        registerEvent(MouseEvent.MOUSE_UP, _ -> removeClass("intellector-prompt-button-pressed"));
        registerEvent(MouseEvent.CLICK, _ -> onSelect());
    }

    private function fitSlot(slotDiameter:Float):Void
    {
        slot.width = slotDiameter;
        slot.height = slotDiameter;
        setRadius(slot, slotDiameter / 2);

        // The art fits a box a little smaller than the slot, so no piece touches its rim.
        var artBox:Float = Math.round(slotDiameter * ART_SHARE);
        art.width = artAspectRatio >= 1 ? artBox : artBox * artAspectRatio;
        art.height = artAspectRatio >= 1 ? artBox / artAspectRatio : artBox;
    }

    // HaxeUI doesn't resolve a percentage border-radius, so a circle is always a pixel radius.
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
