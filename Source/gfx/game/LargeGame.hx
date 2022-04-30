package gfx.game;

import gfx.utils.PlyScrollType;
import utils.TimeControl;
import struct.PieceColor;
import struct.ActualizationData;
import gfx.common.ActionBar.ActionBtn;
import gameboard.GameBoard;
import haxe.ui.containers.Box;

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/large_game.xml"))
class LargeGame extends Box implements IGameLayout
{
    private var board:GameBoard;
    private var sidebox:Sidebox;
    private var chatbox:Chatbox;
    private var gameinfobox:GameInfoBox;

    private var MIN_SIDEBARS_WIDTH:Float = 100;
    private var MAX_SIDEBARS_WIDTH:Float = 350;
    

    public function refreshLayout()
    {
        var hexSideLength:Float = boardContainer.height / 14;
        board.resize(hexSideLength);
        boardWrapper.refreshLayout();
        boardWrapper.syncDimensionsUpstream();
        boardContainer.width = boardWrapper.width;
        boardContainer.height = boardWrapper.height;
        leftBox.percentWidth = 50;
        rightBox.percentWidth = 50;
        this.validateNow();

        if (leftBox.width > MAX_SIDEBARS_WIDTH)
        {
            leftBox.width = MAX_SIDEBARS_WIDTH;
            rightBox.width = MAX_SIDEBARS_WIDTH;
            contentHBox.autoSize();
            this.validateNow();
        }
        else if (leftBox.width < MIN_SIDEBARS_WIDTH)
        {
            leftBox.hidden = true;
            rightBox.percentWidth = 100;
            contentHBox.autoSize();
            this.validateNow();
        }
        //TODO: Yet the same condition is used for determining whether to use CompactGame
    }

    //TODO: Why is it possible to set board's orientation from various places?
    public static function constructFromActualizationData(board:GameBoard, actualizationData:ActualizationData, orientationColor:PieceColor, onActionBtnPressed:ActionBtn->Void, onPlyScrollBtnPressed:PlyScrollType->Void):LargeGame
    {
        if (orientationColor == Black)
            board.revertOrientation();

        var playingAs:Null<PieceColor> = actualizationData.logParserOutput.getPlayerColor();

        if (orientationColor == null)
            if (playingAs == null)
                orientationColor = White;
            else
                orientationColor = playingAs;

        var sidebox = Sidebox.constructFromActualizationData(actualizationData, orientationColor, onActionBtnPressed, onPlyScrollBtnPressed);
        var chatbox = Chatbox.constructFromActualizationData(playingAs == null, actualizationData);
        var gameinfobox = GameInfoBox.constructFromActualizationData(actualizationData);

        return new LargeGame(board, sidebox, chatbox, gameinfobox);
    }

    public static function constructFromParams(board:GameBoard, whiteLogin:String, blackLogin:String, orientationColor:PieceColor, timeControl:TimeControl, playerColor:Null<PieceColor>, onActionBtnPressed:ActionBtn->Void, onPlyScrollBtnPressed:PlyScrollType->Void):LargeGame 
    {
        if (orientationColor == Black)
            board.revertOrientation();

        var sidebox = new Sidebox(playerColor, timeControl, whiteLogin, blackLogin, orientationColor, onActionBtnPressed, onPlyScrollBtnPressed);
        var chatbox = new Chatbox(playerColor == null);
        var gameinfobox = new GameInfoBox(timeControl, whiteLogin, blackLogin);

        return new LargeGame(board, sidebox, chatbox, gameinfobox);
    }

    private function new(board:GameBoard, sidebox:Sidebox, chatbox:Chatbox, gameinfobox:GameInfoBox)
    {
        super();
        this.board = board;

        boardWrapper.autoDownstreamSync = false;
        boardWrapper.sprite = board;

        leftBox.addComponent(gameinfobox);
        leftBox.addComponent(chatbox);

        rightBox.addComponent(sidebox);
    }
}