package gfx.game;

import openfl.display.BitmapData;
import gfx.components.BoardWrapper;
import gameboard.Board;
import struct.Situation;
import struct.Ply;
import gif.Gif;
import haxe.Timer;
import gfx.components.Dialogs;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/live/share_game_tab.xml"))
class ShareGameTab extends Box
{
    private var plySequence:Array<Ply>;

    @:bind(copyLinkBtnTick, MouseEvent.CLICK)
    @:bind(copyLinkBtn, MouseEvent.CLICK)
    private function onCopyLinkPressed(e)
    {
        Browser.navigator.clipboard.writeText(linkTextField.text)
            .catchError(e -> {Dialogs.alert(Dictionary.getPhrase(CLIPBOARD_ERROR_ALERT_TEXT, ['$e']), Dictionary.getPhrase(CLIPBOARD_ERROR_ALERT_TITLE));})
            .finally(() -> {
                copyLinkBtn.hidden = true;
                copyLinkBtnTick.hidden = false;
                Timer.delay(() -> {
                    copyLinkBtnTick.hidden = true;
                    copyLinkBtn.hidden = false;
                }, 500);
            });
    }

    @:bind(copyPINBtnTick, MouseEvent.CLICK)
    @:bind(copyPINBtn, MouseEvent.CLICK)
    private function onCopyPINPressed(e)
    {
        Browser.navigator.clipboard.writeText(pinTextArea.text)
            .catchError(e -> {Dialogs.alert(Dictionary.getPhrase(CLIPBOARD_ERROR_ALERT_TEXT, ['$e']), Dictionary.getPhrase(CLIPBOARD_ERROR_ALERT_TITLE));})
            .finally(() -> {
                copyPINBtn.hidden = true;
                copyPINBtnTick.hidden = false;
                Timer.delay(() -> {
                    copyPINBtnTick.hidden = true;
                    copyPINBtn.hidden = false;
                }, 500);
            });
    }
    
    @:bind(downloadGifBtn, MouseEvent.CLICK)
    private function onDownloadGIFPressed(e)
    {
        var img:Gif = new Gif(720, 720, 1);
        var board:Board = new Board(Situation.starting(), White, BoardWrapper.widthToHexSideLength(720), None);

        var bitmapData:BitmapData = new BitmapData(720, 720);
        bitmapData.draw(board);
        img.addFrame(bitmapData);

        for (ply in plySequence)
        {
            board.applyPremoveTransposition(ply);
            bitmapData = new BitmapData(720, 720);
            bitmapData.draw(board);
            img.addFrame(bitmapData);
        }

        img.save("board.gif");
    }

    public function init(gameLink:String, pin:String, plySequence:Array<Ply>)
    {
        linkTextField.text = gameLink;
        pinTextArea.text = pin;
        this.plySequence = plySequence;
    }

    public function new()
    {
        super();
    }
}