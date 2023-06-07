package gfx.popups;

import gfx.game.board.subcomponents.Piece;
import dict.Dictionary;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.events.UIEvent;
import net.shared.board.Rules;
import haxe.ui.components.Image;
import net.shared.PieceColor;
import haxe.ui.components.Button;
import net.shared.PieceType;
import gfx.basic_components.BaseDialog;
import haxe.ui.core.Screen as HaxeUIScreen;
import assets.Paths;

@:build(haxe.ui.ComponentBuilder.build('assets/layouts/popups/promotion_select.xml'))
class PromotionSelect extends BaseDialog
{
    private var pieceButtons:Map<PieceType, Button> = [];
    private var pieceBtnIcons:Map<PieceType, Image> = [];

    private var playerColor:PieceColor;
    private var onPieceSelected:PieceType->Void;

    public function new(playerColor:PieceColor, onPieceSelected:PieceType->Void)
    {
        super(null, true);
        this.buttons = DialogButton.CANCEL;
        this.playerColor = playerColor;
        this.onPieceSelected = onPieceSelected;

        for (type in Rules.possiblePromotionTypes())
            btnsBox.addComponent(pieceBtn(type, playerColor));
    }

    private function resize()
    {
        var btnSize:Float = Math.min(100, Math.min(HaxeUIScreen.instance.actualHeight * 0.5, HaxeUIScreen.instance.actualWidth * 0.2));

        for (button in pieceButtons)
        {
            button.width = btnSize;
            button.height = btnSize;
        }

        for (type => icon in pieceBtnIcons)
        {
            var iconSize:Float = 0.8 * Piece.pieceRelativeScale(type) * btnSize;
            icon.width = iconSize;
            icon.height = iconSize;
        }
    }

    private function onClose(button)
    {
        //* Do nothing
    }

    private function onPieceBtnPressed(type:PieceType, e) 
    {
        hideDialog(DialogButton.OK);
        onPieceSelected(type);
    }

    private function onBtnReady(type:PieceType, btn:Button, e)
    {
        pieceButtons.set(type, btn);
        pieceBtnIcons.set(type, btn.findComponent(Image));
        resize();
    }

    private function pieceBtn(type:PieceType, color:PieceColor):Button
    {
        var btn:Button = new Button();
        btn.icon = Paths.piece(type, color);
        btn.onClick = onPieceBtnPressed.bind(type);
        btn.registerEvent(UIEvent.READY, onBtnReady.bind(type, btn));
        return btn;
    }
}