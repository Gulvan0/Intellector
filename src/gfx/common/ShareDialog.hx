package gfx.common;

import gameboard.util.BoardSize;
import gfx.profile.data.StudyData;
import gfx.popups.StudyParamsDialog;
import net.shared.dataobj.StudyInfo;
import net.shared.board.RawPly;
import struct.Variant;
import gfx.popups.StudyParamsDialog.StudyParamsDialogMode;
import haxe.ui.util.Color;
import haxe.ui.core.Screen;
import haxe.ui.events.FocusEvent;
import haxe.ui.events.UIEvent;
import js.lib.ArrayBufferView;
import js.lib.ArrayBuffer;
import gameboard.GameBoard;
import haxe.io.Bytes;
import js.html.Blob;
import haxe.Timer;
import gfx.Dialogs;
import js.Browser;
import net.shared.PieceColor;
import gameboard.Board;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.dialogs.Dialog;
import dict.Dictionary;
import net.shared.board.Situation;
import net.shared.utils.MathUtils;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/common/share_dialog.xml"))
class ShareDialog extends Dialog 
{   
    private var situation:Situation;
    private var orientation:PieceColor;
    
    @:bind(downloadPNGBtn, MouseEvent.CLICK)
    public function onDownloadPNGPressed(e) 
    {
        var pngWidth:Int = Std.parseInt(pngWidthTF.text);
        var pngHeight:Int = Std.parseInt(pngHeightTF.text);
        var estimatedThickness:Int = Math.ceil((3/560) * pngWidth);
        var boardWidth:Int = pngWidth - estimatedThickness - 2;
        var boardHeight:Int = pngHeight - estimatedThickness - 2;
        var backgroundColor:Color = transparentBackgroundCheckbox.selected? 0x00000000 : (0xFF000000 | cast(colorPicker.selectedItem, Color));
        var addLetters:Bool = addMarkingCheckbox.selected;

        if (BoardSize.inverseAspectRatio(addLetters) * boardWidth > boardHeight)
            boardWidth = Math.floor(boardHeight / BoardSize.inverseAspectRatio(addLetters));
        else
            boardHeight = Math.floor(boardWidth * BoardSize.inverseAspectRatio(addLetters));

        var aParam:String = "png";
        var wParam:String = Std.string(pngWidth);
        var hParam:String = Std.string(pngHeight);
        var bParam:String = backgroundColor.toHex().substr(1);
        var oParam:String = orientation == White? "w" : "b";
        var sParam:String = StringTools.urlEncode(situation.serialize());

        var url:String = 'https://intellector.info/tools/gen/?a=$aParam&w=$wParam&h=$hParam&b=$bParam&o=$oParam&s=$sParam';

        if (addLetters)
            url += "&l=t";

        Browser.window.open(url, "_blank");
    }

    public function showShareDialog(mutedGameboard:GameBoard)
    {
        mutedGameboard.suppressLMBHandler = true;
        mutedGameboard.suppressRMBHandler = true;

        onDialogClosed = e -> {
            mutedGameboard.suppressLMBHandler = false;
            mutedGameboard.suppressRMBHandler = false;
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
    }
    
    @:bind(preserveAspectRatioCheckbox, UIEvent.CHANGE)
    public function onKeepRatioCheckChanged(e) 
    {
        if (preserveAspectRatioCheckbox.selected)
        {
            pngHeightTF.text = "" + Math.ceil(BoardSize.inverseAspectRatio(addMarkingCheckbox.selected) * Std.parseInt(pngWidthTF.text));
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
    
    @:bind(addMarkingCheckbox, UIEvent.CHANGE)
    public function onAddMarkingCheckChanged(e) 
    {
        if (addMarkingCheckbox.selected && preserveAspectRatioCheckbox.selected)
            pngHeightTF.text = "" + Math.ceil(BoardSize.inverseAspectRatio(true) * Std.parseInt(pngWidthTF.text));
    }
    
    @:bind(pngWidthTF, FocusEvent.FOCUS_OUT)
    public function onWidthFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(pngWidthTF.text);
        if (value == null)
            pngWidthTF.text = "" + MathUtils.clampI(Math.ceil(Std.parseInt(pngHeightTF.text) / BoardSize.inverseAspectRatio(addMarkingCheckbox.selected)), 100, 2048);
        else
        {
            var clampedValue:Int = MathUtils.clampI(value, 100, 2048);
            pngWidthTF.text = "" + clampedValue;
            if (preserveAspectRatioCheckbox.selected)
                pngHeightTF.text = "" + Math.ceil(BoardSize.inverseAspectRatio(addMarkingCheckbox.selected) * clampedValue);
        }
    }
    
    @:bind(pngHeightTF, FocusEvent.FOCUS_OUT)
    public function onHeightFocusLost(e) 
    {
        var value:Null<Int> = Std.parseInt(pngHeightTF.text);
        if (value == null)
            pngHeightTF.text = "" + MathUtils.clampI(Math.ceil(BoardSize.inverseAspectRatio(addMarkingCheckbox.selected) * Std.parseInt(pngWidthTF.text)), 100, 2048);
        else
        {
            var clampedValue:Int = MathUtils.clampI(value, 100, 2048);
            if (preserveAspectRatioCheckbox.selected)
                pngWidthTF.text = "" + Math.ceil(clampedValue / BoardSize.inverseAspectRatio(addMarkingCheckbox.selected));
            pngHeightTF.text = "" + clampedValue;
        }
    }

    public function initInGame(situation:Situation, orientation:PieceColor, gameLink:String, pin:String, startingSituation:Situation, plySequence:Array<RawPly>)
    {
        init(situation, orientation);
        tabView.removeComponent(shareExportTab);
        shareGameTab.init(gameLink, pin, startingSituation, plySequence);
    }

    public function initInAnalysis(situation:Situation, orientation:PieceColor, variant:Variant, ?exploredStudyData:StudyData)
    {
        init(situation, orientation);
        tabView.removeComponent(shareGameTab);

        if (Networker.isConnectedToServer())
        {
            var studyParamsDialogMode:StudyParamsDialogMode;
            if (exploredStudyData != null && LoginManager.isPlayer(exploredStudyData.ownerLogin))
                studyParamsDialogMode = CreateOrOverwrite(variant, exploredStudyData.id, exploredStudyData.info);
            else
                studyParamsDialogMode = Create(variant);
    
            exportStudyBtn.onClick = e -> {
                hideDialog(null);
                Dialogs.getQueue().add(new StudyParamsDialog(studyParamsDialogMode));
            }
        }
        else
            tabView.removeComponent(shareExportTab);
    }

    private function init(situation:Situation, orientation:PieceColor)
    {
        var board:Board = new Board(situation, orientation, None);
        board.percentWidth = 100;
        board.percentHeight = 100;
        boardContainer.addComponent(board);

        sipText.copiedText = situation.serialize();

        pngWidthTF.text = "720";
        pngHeightTF.text = "" + Math.ceil(BoardSize.inverseAspectRatio(addMarkingCheckbox.selected) * 720);

        this.situation = situation;
        this.orientation = orientation;
    }

    public function new()
    {
        super();
        buttons = null;
    }
}