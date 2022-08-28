package gfx.common;

import haxe.ui.util.Color;
import haxe.ui.core.Screen;
import openfl.geom.Matrix;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.UIEvent;
import openfl.events.Event;
import js.lib.ArrayBufferView;
import js.lib.ArrayBuffer;
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

class ImageExportData
{
    public final board:Board;
    public final pngWidth:Int;
    public final pngHeight:Int;
    public final backgroundColor:Int;
    public final transform:Matrix;

    public function new(board:Board, pngWidth:Int, pngHeight:Int, boardWidth:Int, boardHeight:Int, backgroundColor:Int)
    {
        this.board = board;
        this.pngWidth = pngWidth;
        this.pngHeight = pngHeight;
        this.backgroundColor = backgroundColor;
        this.transform = new Matrix();
        this.transform.translate(Math.round((pngWidth - boardWidth)/2), Math.round((pngHeight - boardHeight)/2));
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("Assets/layouts/common/share_dialog.xml"))
class ShareDialog extends Dialog 
{   
    private var situation:Situation;
    private var orientation:PieceColor;

    private var pngExportData:ImageExportData;

    private var boardWrapper:BoardWrapper;

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

    private function onReadyForPNGExport(e)
    {
        pngExportData.board.removeEventListener(Event.EXIT_FRAME, onReadyForPNGExport);

        var image:BitmapData = new BitmapData(pngExportData.pngWidth, pngExportData.pngHeight, true, pngExportData.backgroundColor);
        image.draw(pngExportData.board, pngExportData.transform);

        stage.removeChild(pngExportData.board);
        pngExportData = null;

        var blob:Blob = new Blob([image.image.encode(PNG).getData()], {type: 'image/png'});
        var rand:Int = MathUtils.randomInt(1, 1000000);
        FileSaver.saveAs(blob, 'intpos_$rand.png');
    }
    
    @:bind(downloadPNGBtn, MouseEvent.CLICK)
    public function onDownloadPNGPressed(e) 
    {
        var pngWidth:Int = Std.parseInt(pngWidthTF.text);
        var pngHeight:Int = Std.parseInt(pngHeightTF.text);
        var estimatedThickness:Int = Math.ceil((3/560) * pngWidth);
        var boardWidth:Int = pngWidth - estimatedThickness - 2;
        var boardHeight:Int = pngHeight - estimatedThickness - 2;

        if (BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * boardWidth > boardHeight)
            boardWidth = Math.floor(boardHeight / BoardWrapper.invAspectRatio(addMarkupCheckbox.selected));
        else
            boardHeight = Math.floor(boardWidth * BoardWrapper.invAspectRatio(addMarkupCheckbox.selected));

        var hexSideLength:Float = BoardWrapper.widthToHexSideLength(boardWidth);
        var backgroundColor:Int = transparentBackgroundCheckbox.selected? 0x00000000 : 0xFF000000 | cast(colorPicker.selectedItem, Color).toInt();
        
        var board:Board = new Board(situation, orientation, hexSideLength, addMarkupCheckbox.selected? Over : None);
        pngExportData = new ImageExportData(board, pngWidth, pngHeight, boardWidth, boardHeight, backgroundColor);

        board.addEventListener(Event.EXIT_FRAME, onReadyForPNGExport);
        stage.addChild(board);
    }

    public function showShareDialog(mutedGameboard:GameBoard)
    {
        mutedGameboard.suppressLMBHandler = true;
        mutedGameboard.suppressRMBHandler = true;

        onDialogClosed = e -> {
            mutedGameboard.suppressLMBHandler = false;
            mutedGameboard.suppressRMBHandler = false;
            boardContainer.removeComponent(boardWrapper);
        };

        if (Screen.instance.actualWidth < 600 || Screen.instance.actualHeight < 500)
        {
            pngExportParamsBox.hidden = true;
            boardContainer.percentWidth = 100;
        }
        else
        {
            pngExportParamsBox.hidden = false;
            boardContainer.percentWidth = 50;
        }

        this.percentWidth = MathUtils.clamp(900 / Screen.instance.actualWidth, 0.5, 0.95) * 100;
        this.percentHeight = MathUtils.clamp(600 / Screen.instance.actualHeight, 0.5, 0.95) * 100;

        showDialog(false);
        boardContainer.addComponent(boardWrapper);
    }
    
    @:bind(preserveAspectRatioCheckbox, UIEvent.CHANGE)
    public function onKeepRatioCheckChanged(e) 
    {
        if (preserveAspectRatioCheckbox.selected)
        {
            pngHeightTF.text = "" + Math.ceil(BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * Std.parseInt(pngWidthTF.text));
            pngHeightTF.disabled = true;
        }
        else
            pngHeightTF.disabled = false;
    }
    
    @:bind(transparentBackgroundCheckbox, UIEvent.CHANGE)
    public function onTransparentBGCheckChanged(e) 
    {
        bgColorBox.disabled = transparentBackgroundCheckbox.selected;
    }
    
    @:bind(addMarkupCheckbox, UIEvent.CHANGE)
    public function onAddMarkupCheckChanged(e) 
    {
        if (addMarkupCheckbox.selected && preserveAspectRatioCheckbox.selected)
            pngHeightTF.text = "" + Math.ceil(BoardWrapper.invAspectRatio(true) * Std.parseInt(pngWidthTF.text));
    }
    
    @:bind(pngWidthTF, FocusEvent.FOCUS_OUT)
    public function onWidthFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(pngWidthTF.text);
        if (value == null)
            pngWidthTF.text = "" + MathUtils.clampI(Math.ceil(Std.parseInt(pngHeightTF.text) / BoardWrapper.invAspectRatio(addMarkupCheckbox.selected)), 100, 2048);
        else
        {
            var clampedValue:Int = MathUtils.clampI(value, 100, 2048);
            pngWidthTF.text = "" + clampedValue;
            if (preserveAspectRatioCheckbox.selected)
                pngHeightTF.text = "" + Math.ceil(BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * clampedValue);
        }
    }
    
    @:bind(pngHeightTF, FocusEvent.FOCUS_OUT)
    public function onHeightFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(pngHeightTF.text);
        if (value == null)
            pngHeightTF.text = "" + MathUtils.clampI(Math.ceil(BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * Std.parseInt(pngWidthTF.text)), 100, 2048);
        else
        {
            var clampedValue:Int = MathUtils.clampI(value, 100, 2048);
            if (preserveAspectRatioCheckbox.selected)
                pngWidthTF.text = "" + Math.ceil(clampedValue / BoardWrapper.invAspectRatio(addMarkupCheckbox.selected));
            pngHeightTF.text = "" + clampedValue;
        }
    }

    public function initInGame(situation:Situation, orientation:PieceColor, gameLink:String, pin:String, startingSituation:Situation, plySequence:Array<Ply>)
    {
        init(situation, orientation);
        shareGameTab.init(gameLink, pin, startingSituation, plySequence);
        tabView.removeComponent(shareExportTab);
    }

    public function initInAnalysis(situation:Situation, orientation:PieceColor, exportNewCallback:(name:String)->Void, ?overwriteCallback:(newName:String)->Void, ?oldStudyName:String)
    {
        init(situation, orientation);
        shareExportTab.init(exportNewCallback, overwriteCallback, oldStudyName);
        tabView.removeComponent(shareGameTab);
    }

    private function init(situation:Situation, orientation:PieceColor)
    {
        var board:Board = new Board(situation, orientation, 40, None);

        sipTextField.text = situation.serialize();

        boardWrapper = new BoardWrapper(board);
        boardWrapper.percentWidth = 100;
        boardWrapper.maxPercentHeight = 100;
        boardWrapper.horizontalAlign = 'center';
        boardWrapper.verticalAlign = 'center';

        pngWidthTF.text = "720";
        pngHeightTF.text = "" + Math.ceil(BoardWrapper.invAspectRatio(addMarkupCheckbox.selected) * 720);

        this.situation = situation;
        this.orientation = orientation;
    }

    public function new()
    {
        super();
        buttons = null;
    }
}