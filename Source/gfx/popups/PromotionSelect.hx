package gfx.popups;

import dict.Dictionary;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.events.UIEvent;
import net.shared.board.Rules;
import haxe.ui.components.Image;
import net.shared.PieceColor;
import haxe.ui.components.Button;
import openfl.events.Event;
import utils.AssetManager;
import net.shared.PieceType;
import gfx.basic_components.BaseDialog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/popups/promotion_select.xml'))
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
        var iconSize:Float = 0.8 * btnSize;

        for (button in pieceButtons)
        {
            button.width = btnSize;
            button.height = btnSize;
        }

        for (type => icon in pieceBtnIcons)
        {
            var ratio:Float = AssetManager.pieceAspectRatio(type, playerColor);

            if (ratio > 1)
            {
                icon.width = AssetManager.pieceRelativeScale(type) * iconSize;
                icon.height = icon.width / ratio;
            }
            else
            {
                icon.height = AssetManager.pieceRelativeScale(type) * iconSize;
                icon.width = icon.height * ratio;
            }
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
        btn.icon = AssetManager.piecePath(type, color);
        btn.onClick = onPieceBtnPressed.bind(type);
        btn.registerEvent(UIEvent.READY, onBtnReady.bind(type, btn));
        return btn;
    }
}