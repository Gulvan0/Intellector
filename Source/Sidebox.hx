package;

import haxe.ui.components.VerticalScroll;
import openfl.display.StageAlign;
import haxe.Timer;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.macros.ComponentMacros;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import openfl.display.Sprite;

class Sidebox extends Sprite
{

    private var bottomTime:Label;
    private var upperTime:Label;
    private var bottomLogin:Label;
    private var upperLogin:Label;
    private var movetable:TableView;

    private var timer:Timer;
    private var secsPerTurn:Int;
    private var move:Int;

    private var playerColor:PieceColor;
    private var playerTurn:Bool;
    private var lastMove:Dynamic;

    private inline function numRep(v:Int)
    {
        return v < 10? '0$v' : '$v';
    }

    private function secsToString(secs:Int) 
    {
        var secsLeft:Int = secs % 60;
        var minsLeft:Int = cast (secs - secsLeft)/60;
        var minRepresentation = numRep(minsLeft);
        var secRepresentation = numRep(secsLeft);
        return '$minRepresentation:$secRepresentation';    
    }

    private function timerRun() 
    {
        var timeLabel = playerTurn? bottomTime : upperTime;
        var timeNumbers = timeLabel.text.split(":");
        if (timeNumbers[1] == "00")
        {
            if (timeNumbers[0] == "00")
            {
                terminate();
                Networker.reqTimeoutCheck();
                return;
            }
            timeLabel.text = '${numRep(Std.parseInt(timeNumbers[0])-1)}:59';
        }
        else
            timeLabel.text = '${timeNumbers[0]}:${numRep(Std.parseInt(timeNumbers[1])-1)}';
    }

    private function addBonus(text:String) 
    {
        var timeNumbers = text.split(":").map(Std.parseInt);
        timeNumbers[0] += Math.floor((timeNumbers[1] + secsPerTurn) / 60);
        timeNumbers[1] = (timeNumbers[1] + secsPerTurn) % 60;
        return '${numRep(timeNumbers[0])}:${numRep(timeNumbers[1])}';
    }

    public function correctTime(correctedSecsWhite:Int, correctedSecsBlack:Int) 
    {
        if (playerColor == White)
        {
            bottomTime.text = secsToString(correctedSecsWhite);
            upperTime.text = secsToString(correctedSecsBlack);
        }
        else
        {
            upperTime.text = secsToString(correctedSecsWhite);
            bottomTime.text = secsToString(correctedSecsBlack);
        }
    }

    public function makeMove(color:PieceColor, figure:PieceType, to:IntPoint, capture:Bool, mate:Bool, castle:Bool, ?morphInto:PieceType) 
    {
        if (timer != null)
            timer.stop();

        var moveStr;
        if (castle)
            moveStr = "O-O";
        else 
            moveStr = figureAbbreviation(figure) + (capture? "x" : "") + locToStr(to) + (morphInto != null? '=[${figureAbbreviation(morphInto)}]' : '') + (mate? "#" : "");

        if (color == Black)
        {
            lastMove.black_move = moveStr;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMove);
        }
        else 
        {
            lastMove = {"num": '$move', "white_move": moveStr, "black_move": ""};
            movetable.dataSource.add(lastMove);
        }
        waitAndScroll();

        move++;

        if (!mate && move > 2)
        {
            if (playerTurn) //Because corrections have already been applied if it is the opponent's turn ("correct, then move" server rule)
                bottomTime.text = addBonus(bottomTime.text);
            launchTimer();
        }
        
        playerTurn = color != playerColor;
    }

    private function waitAndScroll() 
    {
        var t:Timer = new Timer(100);
        t.run = () -> {
            t.stop(); 
            scrollToMax();
        }    
    }

    private function scrollToMax() 
    {
        var vscroll = movetable.findComponent(VerticalScroll, false);
        if (vscroll != null)
            vscroll.pos = vscroll.max;
    }

    public function writeMove(color:PieceColor, s:String)
    {
        if (color == Black)
        {
            lastMove.black_move = s;
            movetable.dataSource.update(movetable.dataSource.size - 1, lastMove);
        }
        else 
        {
            lastMove = {"num": '$move', "white_move": s, "black_move": ""};
            movetable.dataSource.add(lastMove);
        }

        move++;
        playerTurn = color != playerColor;
    }

    public function launchTimer()
    {
        timer = new Timer(1000);
        timer.run = timerRun;
    }

    public function terminate() 
    {
        if (timer != null)
            timer.stop();
    }

    public function new(startSecs:Int, secsPerTurn:Int, playerLogin:String, opponentLogin:String, playerIsWhite:Bool) 
    {
        super();
        move = 1;
        this.secsPerTurn = secsPerTurn;
        playerColor = playerIsWhite? White : Black;
        playerTurn = playerIsWhite;

        var strStart = secsToString(startSecs);
        var timeStyle:Style = {fontSize: 40};
        var loginStyle:Style = {fontSize: 24};

        var box:VBox = new VBox();

        upperTime = new Label();
        upperTime.text = strStart;
        upperTime.customStyle = timeStyle;
        box.addComponent(upperTime);

        upperLogin = new Label();
        upperLogin.text = opponentLogin;
        upperLogin.customStyle = loginStyle;
        box.addComponent(upperLogin);

        movetable = ComponentMacros.buildComponent("assets/layouts/movetable.xml");
        box.addComponent(movetable);

        bottomLogin = new Label();
        bottomLogin.text = playerLogin;
        bottomLogin.customStyle = loginStyle;
        box.addComponent(bottomLogin);

        bottomTime = new Label();
        bottomTime.text = strStart;
        bottomTime.customStyle = timeStyle;
        box.addComponent(bottomTime);

        addChild(box);
    }
}