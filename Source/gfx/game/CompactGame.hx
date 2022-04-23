package gfx.game;

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

class CompactGame extends VBox
{
    private var creepingLine:CreepingLine;
    private var whiteLogin:Label;
    private var whiteClock:Clock;
    private var board:GameBoard;
    private var blackLogin:Label;
    private var blackClock:Clock;
    private var actionBar:ActionBar;

    private var onActionBtnPressed:ActionBtn->Void;

    private function handleActionBarBtnPress(btn:ActionBtn) 
    {
        if (btn == ChangeOrientation)
            revertOrientation();
        onActionBtnPressed(btn);
    }

    private function revertOrientation()
    {
        //TODO: Rewrite
        /*removeComponent(whiteClock, false);
        removeComponent(blackClock, false);
        removeComponent(whiteLoginCard, false);
        removeComponent(blackLoginCard, false);

        orientationColor = opposite(orientationColor);

        var upperClock:Clock = orientationColor == White? blackClock : whiteClock;
        var bottomClock:Clock = orientationColor == White? whiteClock : blackClock;
        var upperLogin:Card = orientationColor == White? blackLoginCard : whiteLoginCard;
        var bottomLogin:Card = orientationColor == White? whiteLoginCard : blackLoginCard;

        addComponentAt(upperLogin, 0);
        addComponentAt(upperClock, 0);

        addComponent(bottomLogin);
        addComponent(bottomClock);*/
    }

    private function buildLoginLabel(text:String):Label
    {
        var label:Label = new Label();
        label.text = text;
        label.customStyle = {fontSize: 24};
        label.verticalAlign = 'center';
        return label;
    }

    public function init(onActionBtnPressed:ActionBtn->Void)
    {
        this.onActionBtnPressed = onActionBtnPressed;
    }

    public function new(board:GameBoard, playingAs:Null<PieceColor>, timeControl:TimeControl, whiteLoginStr:String, blackLoginStr:String, orientationColor:PieceColor) 
    {
        super();
        this.board = board;
        
        this.creepingLine = new CreepingLine(board.applyScrolling);
        this.whiteLogin = buildLoginLabel(whiteLoginStr);
        this.whiteClock = new Clock();
        this.blackLogin = buildLoginLabel(blackLoginStr);
        this.blackClock = new Clock();
        this.actionBar = new ActionBar();

        whiteClock.init(timeControl.startSecs, playingAs == White, timeControl.startSecs >= 90, true);
        blackClock.init(timeControl.startSecs, playingAs == Black, timeControl.startSecs >= 90, false);

        actionBar.init(true, playingAs, handleActionBarBtnPress);

        var upperSpacer:Spacer = new Spacer();
        upperSpacer.percentWidth = 100;

        var upperHBox:HBox = new HBox();
        upperHBox.addComponent(blackClock);
        upperHBox.addComponent(upperSpacer);
        upperHBox.addComponent(blackLogin);

        var boardWrapper:SpriteWrapper = new SpriteWrapper();
        boardWrapper.sprite = board;

        var lowerSpacer:Spacer = new Spacer();
        lowerSpacer.percentWidth = 100;

        var lowerHBox:HBox = new HBox();
        lowerHBox.addComponent(whiteLogin);
        lowerHBox.addComponent(lowerSpacer);
        lowerHBox.addComponent(whiteClock);

        var vbox:VBox = new VBox();
        vbox.addComponent(creepingLine);
        vbox.addComponent(upperHBox);
        vbox.addComponent(boardWrapper);
        vbox.addComponent(lowerHBox);
        vbox.addComponent(actionBar);

        if (orientationColor == Black)
            revertOrientation();
    }    
}