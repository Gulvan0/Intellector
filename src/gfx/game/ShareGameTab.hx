package gfx.game;

import gameboard.util.BoardSize;
import net.shared.board.RawPly;
import browser.Clipboard;
import haxe.ui.events.FocusEvent;
import haxe.ui.util.Color;
import gameboard.Board;
import haxe.Timer;
import gfx.Dialogs;
import js.Browser;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.Box;
import dict.Dictionary;
import net.shared.board.Situation;
import net.shared.utils.MathUtils;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/share_game_tab.xml"))
class ShareGameTab extends Box
{
    private var plySequence:Array<RawPly>;
    private var startingSituation:Situation;

    @:bind(copyPINBtnTick, MouseEvent.CLICK)
    @:bind(copyPINBtn, MouseEvent.CLICK)
    private function onCopyPINPressed(e)
    {
        Clipboard.copy(pinTextArea.text, onPINCopied);
    }

    private function onPINCopied()
    {
        copyPINBtn.hidden = true;
        copyPINBtnTick.hidden = false;
        Timer.delay(() -> {
            copyPINBtnTick.hidden = true;
            copyPINBtn.hidden = false;
        }, 500);
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

        var gifHeight:Int = Math.ceil(BoardSize.inverseAspectRatio(addMarkingCheckbox.selected) * gifWidth);
        var bgColor:Color = 0xFF000000 | cast(colorPicker.selectedItem, Color);
        var addLetters:Bool = addMarkingCheckbox.selected;

        var aParam:String = "gif";
        var wParam:String = Std.string(gifWidth);
        var hParam:String = Std.string(gifHeight);
        var iParam:String = Std.string(gifInterval);
        var bParam:String = bgColor.toHex().substr(1);
        var oParam:String = "w"; //TODO: Allow users to change board orientation
        var sParam:String = StringTools.urlEncode(startingSituation.serialize());
        var pParam:String = StringTools.urlEncode(plySequence.map(x -> x.serialize()).join(";"));

        var url:String = 'https://intellector.info/tools/gen/?a=$aParam&w=$wParam&h=$hParam&i=$iParam&b=$bParam&o=$oParam&s=$sParam&p=$pParam';

        if (addLetters)
            url += "&l=t";

        Browser.window.open(url, "_blank");
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

    public function init(gameLink:String, pin:String, startingSituation:Situation, plySequence:Array<RawPly>)
    {
        linkText.copiedText = gameLink;
        pinTextArea.text = pin;
        this.plySequence = plySequence;
        this.startingSituation = startingSituation;
    }

    public function new()
    {
        super();
    }
}