package gfx.game;

import haxe.Timer;
import utils.TimeControl;
import struct.PieceColor;
import gfx.components.SpriteWrapper;
import haxe.ui.components.Spacer;
import haxe.ui.containers.HBox;
import gameboard.GameBoard;
import gfx.common.ActionBar;
import gfx.common.Clock;
import haxe.ui.components.Label;
import gfx.common.CreepingLine;
import haxe.ui.containers.VBox;
import openfl.display.Sprite;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/compact_game.xml"))
class CompactGame extends VBox implements IGameLayout
{
    private var board:GameBoard;

    private var orientationColor:PieceColor;
    private var onActionBtnPressed:ActionBtn->Void;

    public function refreshLayout()
    {
        //Calculate the available size using haxeui
        gameContentsBox.percentHeight = 100;
        boardContainer.percentWidth = 100;
        boardContainer.percentHeight = 100;
        this.validateNow();

        //Resize everything related to gameboard according to the calculated size
        var boardWH:Float = Math.min(boardContainer.width, boardContainer.height);
        var hexSideLength:Float = boardWH / 14;
        board.resize(hexSideLength);
        boardWrapper.refreshLayout();
        boardWrapper.syncDimensionsUpstream();
        boardContainer.width = boardWrapper.width;
        boardContainer.height = boardWrapper.height;
        gameContentsBox.autoSize();
        this.validateNow();
    }

    private function handleActionBarBtnPress(btn:ActionBtn) 
    {
        if (btn == ChangeOrientation)
            revertOrientation();
        onActionBtnPressed(btn);
    }

    private function revertOrientation()
    {
        gameContentsBox.removeComponentAt(2, false);
        gameContentsBox.removeComponentAt(0, false);

        orientationColor = opposite(orientationColor);

        var upperBox:HBox = orientationColor == White? blackHBox : whiteHBox;
        var lowerBox:HBox = orientationColor == White? whiteHBox : blackHBox;

        gameContentsBox.addComponentAt(upperBox, 0);
        gameContentsBox.addComponentAt(lowerBox, 2);
    }

    //TODO: From actualization

    public function new(board:GameBoard, playingAs:Null<PieceColor>, timeControl:TimeControl, whiteLoginStr:String, blackLoginStr:String, orientationColor:PieceColor, onActionBtnPressed:ActionBtn->Void) 
    {
        super();
        this.board = board;
        this.orientationColor = White;
        this.onActionBtnPressed = onActionBtnPressed;

        boardWrapper.autoDownstreamSync = false;
        boardWrapper.sprite = board;

        whiteLogin.text = whiteLoginStr;
        blackLogin.text = blackLoginStr;

        whiteClock.resize(30);
        blackClock.resize(30);

        creepLine.init(board.scrollToMove);

        whiteClock.init(timeControl.startSecs, playingAs == White, timeControl.startSecs >= 90, true);
        blackClock.init(timeControl.startSecs, playingAs == Black, timeControl.startSecs >= 90, false);

        actionBar.init(true, playingAs, handleActionBarBtnPress);

        if (orientationColor == Black)
            revertOrientation();
    }    
}