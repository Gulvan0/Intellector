package gfx.common;

import gameboard.GameBoard;
import struct.Ply;
import utils.MathUtils;
import haxe.io.Bytes;
import openfl.utils.ByteArray;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;
import js.html.Blob;
import js.html.FileSaver;
import haxe.Timer;
import gfx.components.Dialogs;
import js.Browser;
import struct.PieceColor;
import gameboard.Board;
import gfx.components.BoardWrapper;
import struct.Situation;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialog;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/share_dialog.xml"))
class ShareDialog extends Dialog 
{   
    private var positionBoard:Board;

    @:bind(copySIPBtn, MouseEvent.CLICK)
    @:bind(copySIPBtnTick, MouseEvent.CLICK)
    public function onCopySIPPressed(e) 
    {
        Browser.navigator.clipboard.writeText(sipTextField.text)
            .catchError(e -> {Dialogs.alert('Failed to copy: $e', "Clipboard Error");})
            .finally(() -> {
                copySIPBtn.hidden = true;
                copySIPBtnTick.hidden = false;
                Timer.delay(() -> {
                    copySIPBtnTick.hidden = true;
                    copySIPBtn.hidden = false;
                }, 500);
            });
    }
    
    @:bind(downloadPNGBtn, MouseEvent.CLICK)
    public function onDownloadPNGPressed(e) 
    {
        var image:BitmapData = new BitmapData(Std.int(positionBoard.width), Std.int(positionBoard.height));
        image.draw(positionBoard);

        var b:ByteArray = image.encode(new Rectangle(0, 0, Std.int(positionBoard.width), Std.int(positionBoard.height)), new openfl.display.PNGEncoderOptions());
        var blob:Blob = new Blob([b.toString()], {type: 'image/png'});
        var rand:Int = MathUtils.randomInt(1, 1000000);
        FileSaver.saveAs(blob, 'intpos_$rand.png');
    }

    public function showShareDialog(mutedGameboard:GameBoard)
    {
        mutedGameboard.suppressLMBHandler = true;
        mutedGameboard.suppressRMBHandler = true;
        onDialogClosed = e -> {
            mutedGameboard.suppressLMBHandler = false;
            mutedGameboard.suppressRMBHandler = false;
        };
        showDialog(false);
    }

    public function initInGame(situation:Situation, orientation:PieceColor, gameLink:String, pin:String, plySequence:Array<Ply>)
    {
        init(situation, orientation);
        shareGameTab.init(gameLink, pin, plySequence);
        shareGameTab.hidden = false;
    }

    public function initInAnalysis(situation:Situation, orientation:PieceColor, exportNewCallback:(name:String)->Void, ?overwriteCallback:(newName:String)->Void, ?oldStudyName:String)
    {
        init(situation, orientation);
        shareExportTab.init(exportNewCallback, overwriteCallback, oldStudyName);
        shareExportTab.hidden = false;
    }

    private function init(situation:Situation, orientation:PieceColor)
    {
        positionBoard = new Board(situation, orientation, 40, true);

        sipTextField.text = situation.serialize();

        var boardWrapper:BoardWrapper = new BoardWrapper(positionBoard);
        boardWrapper.percentWidth = 100;
        boardWrapper.maxPercentHeight = 100;
        boardContainer.addComponent(boardWrapper);
    }

    public function new()
    {
        super();
        buttons = null;
    }
}