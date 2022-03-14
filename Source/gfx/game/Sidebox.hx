package gfx.game;

import net.EventProcessingQueue.INetObserver;
import net.ServerEvent;
import gfx.common.Clock;
import haxe.ui.containers.Card;
import dict.Phrase;
import gfx.utils.PlyScrollType;
import gfx.common.MoveNavigator;
import haxe.ui.components.Button;
import haxe.ui.util.Color;
import dict.Dictionary;
import js.Browser;
import haxe.ui.containers.HBox;
import struct.Situation;
import struct.Ply;
import haxe.ui.components.VerticalScroll;
import openfl.display.StageAlign;
import haxe.Timer;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import haxe.ui.containers.TableView;
import haxe.ui.components.Label;
import openfl.display.Sprite;
using utils.CallbackTools;

enum SideboxEvent
{
    ChangeOrientationPressed;
    ResignPressed;
    OfferDrawPressed;
    CancelDrawPressed;
    AcceptDrawPressed;
    DeclineDrawPressed;
    OfferTakebackPressed;
    CancelTakebackPressed;
    AcceptTakebackPressed;
    DeclineTakebackPressed;
    RematchRequested;
    ExportSIPRequested;
    ExploreInAnalysisRequest;
    PlyScrollRequest(type:PlyScrollType);
}

interface ISideboxObserver 
{
    public function handleSideboxEvent(event:SideboxEvent):Void;    
}

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/sidebox.xml'))
class Sidebox extends VBox implements INetObserver
{
    private var enableTakebackAfterMove:Int;
    private var belongsToSpectator:Bool;
    private var orientationColor:PieceColor;
    private var move:Int;

    private var secsPerTurn:Int;
    private var lastMovetableEntry:Dynamic;

    private var observers:Array<ISideboxObserver> = [];

    public function addObserver(obs:ISideboxObserver) 
    {
        observers.push(obs);
    }

    public function removeObserver(obs:ISideboxObserver) 
    {
        observers.remove(obs);
    }

    public function emit(event:SideboxEvent) 
    {
        for (obs in observers)
            obs.handleSideboxEvent(event);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        //TODO: Fill
    }

    //TODO: Maybe implement handleGameboardEvent()

    //TODO: Also make most of the currently public methods private as the references become weak thanks to observer pattern

    private function changeActionButtons(shownButtons:Array<Button>)
    {
        for (i in 0...actionBar.numComponents)
            actionBar.getComponentAt(i).hidden = true;

        var btnWidth:Float = 100 / shownButtons.length;
        for (btn in shownButtons)
        {
            btn.hidden = false;
            btn.percentWidth = btnWidth;
        }
    }

    public function correctTime(correctedSecsWhite:Float, correctedSecsBlack:Float, actualTimestamp:Float) 
    {
        whiteClock.correctTime(correctedSecsWhite, actualTimestamp);
        blackClock.correctTime(correctedSecsBlack, actualTimestamp);
    }

    private function revertOrientation()
    {
        removeComponent(whiteClock, false);
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
        addComponent(bottomClock);

        emit(ChangeOrientationPressed);
    }

    public function onGameEnded() 
    {
        whiteClock.stopTimer();
        blackClock.stopTimer();

        if (!belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn, rematchBtn]);
    }

    //========================================================================================================================================================================

    public function makeMove(plyStr:String, isFinal:Bool) 
    {
        move++;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? blackClock : whiteClock;

        justMovedPlayerClock.stopTimer();

        if (!isFinal && move >= 2)
            playerToMoveClock.launchTimer();

        if (!isFinal && move >= 3)
            justMovedPlayerClock.addTime(secsPerTurn);

        navigator.writePlyStr(plyStr, justMovedColor);
        navigator.scrollAfterDelay();

        if (move == enableTakebackAfterMove)
            offerTakebackBtn.disabled = false;

        if (move == 2)
        {
            offerDrawBtn.disabled = false;
            resignBtn.text = "⚐";
            resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_TOOLTIP);
        }
    }

    public function revertPlys(cnt:Int) 
    {
        if (cnt < 1)
            return;
        
        move -= cnt;

        var justMovedColor:PieceColor = move % 2 == 1? White : Black;
        var justMovedPlayerClock:Clock = justMovedColor == White? whiteClock : blackClock;
        var playerToMoveClock:Clock = justMovedColor == Black? blackClock : whiteClock;

        if (cnt % 2 == 1)
        {
            justMovedPlayerClock.stopTimer();
            playerToMoveClock.launchTimer();
        }

        if (!belongsToSpectator)
        {
            takebackRequestBox.hidden = true;
            cancelTakebackBtn.hidden = true;
            offerTakebackBtn.hidden = false;

            if (move < enableTakebackAfterMove)
                offerTakebackBtn.disabled = true;

            if (move < 2)
            {
                offerDrawBtn.disabled = true;
                resignBtn.text = "✖";
                resignBtn.tooltip = Dictionary.getPhrase(RESIGN_BTN_ABORT_TOOLTIP);
            }
        }

        navigator.revertPlys(cnt);
    }

    public function new(playingAs:Null<PieceColor>, startSecs:Int, secsPerTurn:Int, whiteLogin:String, blackLogin:String, orientationColor:PieceColor) 
    {
        super();
        this.belongsToSpectator = playingAs == null;
        this.secsPerTurn = secsPerTurn;
        this.orientationColor = White;
        this.move = 0;

        if (playingAs != null)
            enableTakebackAfterMove = playingAs == White? 1 : 2;
        
        whiteClock.init(startSecs, false, startSecs >= 90);
        blackClock.init(startSecs, !belongsToSpectator, startSecs >= 90);

        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;

        changeOrientationBtn.onClick = revertOrientation.expand();
        resignBtn.onClick = emit.bind(ResignPressed).expand();
        offerDrawBtn.onClick = emit.bind(OfferDrawPressed).expand();
        cancelDrawBtn.onClick = emit.bind(CancelDrawPressed).expand();
        addTimeBtn.onClick = Networker.emitEvent.bind(AddTime).expand();
        offerTakebackBtn.onClick = emit.bind(OfferDrawPressed).expand();
        cancelTakebackBtn.onClick = emit.bind(CancelDrawPressed).expand();
        rematchBtn.onClick = emit.bind(CancelDrawPressed).expand();
        exportSIPBtn.onClick = emit.bind(ExportSIPRequested).expand();
        analyzeBtn.onClick = emit.bind(ExploreInAnalysisRequest).expand();
        declineDrawBtn.onClick = emit.bind(DeclineDrawPressed).expand();
        acceptDrawBtn.onClick = emit.bind(AcceptDrawPressed).expand();
        declineTakebackBtn.onClick = emit.bind(DeclineTakebackPressed).expand();
        acceptTakebackBtn.onClick = emit.bind(AcceptTakebackPressed).expand();
        
        navigator.init(type -> {emit(PlyScrollRequest(type));});

        if (belongsToSpectator)
            changeActionButtons([changeOrientationBtn, analyzeBtn, exportSIPBtn]);
        else
            changeActionButtons([changeOrientationBtn, offerDrawBtn, offerTakebackBtn, resignBtn, addTimeBtn]);

        if (orientationColor == Black)
            revertOrientation();
    }
}