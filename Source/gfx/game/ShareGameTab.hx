package gfx.game;

import openfl.events.Event;
import haxe.ui.events.FocusEvent;
import haxe.ui.util.Color;
import utils.MathUtils;
import Preferences.Markup;
import openfl.display.BitmapData;
import gfx.basic_components.BoardWrapper;
import gameboard.Board;
import struct.Situation;
import struct.Ply;
import gif.Gif;
import haxe.Timer;
import gfx.Dialogs;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
import dict.Dictionary;

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/live/share_game_tab.xml"))
class ShareGameTab extends Box
{
    private var plySequence:Array<Ply>;
    private var startingSituation:Situation;
    
    private var gifExportParams:{board:Board, gifWidth:Int, gifHeight:Int, gifInterval:Float, bgColor:Int};

    @:bind(copyLinkBtnTick, MouseEvent.CLICK)
    @:bind(copyLinkBtn, MouseEvent.CLICK)
    private function onCopyLinkPressed(e)
    {
        Browser.navigator.clipboard.writeText(linkTextField.text)
            .catchError(e -> {Dialogs.alert(CLIPBOARD_ERROR_ALERT_TEXT, CLIPBOARD_ERROR_ALERT_TITLE, ['$e']);})
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
            .catchError(e -> {Dialogs.alert(CLIPBOARD_ERROR_ALERT_TEXT, CLIPBOARD_ERROR_ALERT_TITLE, ['$e']);})
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
        var gifWidth:Int = Std.parseInt(gifWidthTF.text);

        if (gifWidth != null)
            gifWidth = MathUtils.clampI(gifWidth, 100, 2048);
        else
            gifWidth = 720;

        var gifInterval:Float = Std.parseInt(intervalTF.text);

        if (gifInterval != null)
            gifInterval = MathUtils.clamp(gifInterval / 1000, 0.1, 10);
        else
            gifInterval = 1;

        var gifHeight:Int = Math.ceil(BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * gifWidth);
        var bgColor:Int = 0xFF000000 | cast(colorPicker.selectedItem, Color).toInt();
        var hexSideLength:Float = BoardWrapper.widthToHexSideLength(gifWidth);
        var markup:Markup = addMarkupCheckbox.selected? Over : None;

        var board:Board = new Board(startingSituation, White, hexSideLength, markup);
        gifExportParams = {board: board, gifWidth: gifWidth, gifHeight: gifHeight, gifInterval: gifInterval, bgColor: bgColor};

        board.addEventListener(Event.EXIT_FRAME, onReadyForGIFExport);
        stage.addChild(board);
    }

    private function onReadyForGIFExport(e)
    {
        gifExportParams.board.removeEventListener(Event.EXIT_FRAME, onReadyForGIFExport);
        stage.removeChild(gifExportParams.board);

        var img:Gif = new Gif(gifExportParams.gifWidth, gifExportParams.gifHeight, gifExportParams.gifInterval);
        var bitmapData:BitmapData = new BitmapData(gifExportParams.gifWidth, gifExportParams.gifHeight, false, gifExportParams.bgColor);
        bitmapData.draw(gifExportParams.board);
        img.addFrame(bitmapData);

        for (ply in plySequence)
        {
            gifExportParams.board.applyPremoveTransposition(ply);
            bitmapData = new BitmapData(gifExportParams.gifWidth, gifExportParams.gifHeight, false, gifExportParams.bgColor);
            bitmapData.draw(gifExportParams.board);
            img.addFrame(bitmapData);
        }

        img.save("board.gif");
    }

    @:bind(gifWidthTF, FocusEvent.FOCUS_OUT)
    public function onWidthFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(gifWidthTF.text);
        if (value == null)
            gifWidthTF.text = "720";
        else
            gifWidthTF.text = "" + MathUtils.clampI(value, 100, 2048);
    }

    @:bind(intervalTF, FocusEvent.FOCUS_OUT)
    public function onIntervalFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(intervalTF.text);
        if (value == null)
            intervalTF.text = "1000";
        else
            intervalTF.text = "" + MathUtils.clampI(value, 100, 10000);
    }

    public function init(gameLink:String, pin:String, startingSituation:Situation, plySequence:Array<Ply>)
    {
        linkTextField.text = gameLink;
        pinTextArea.text = pin;
        this.plySequence = plySequence;
        this.startingSituation = startingSituation;
    }

    public function new()
    {
        super();
    }
}