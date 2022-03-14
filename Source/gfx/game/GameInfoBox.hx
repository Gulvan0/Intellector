package gfx.game;

import net.EventProcessingQueue.INetObserver;
import gameboard.GameBoard.IGameBoardObserver;
import struct.IntPoint;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gameboard.GameBoard.GameBoardEvent;
import net.ServerEvent;
import utils.TimeControl;
import haxe.ui.containers.Card;
import haxe.ui.containers.VBox;
import gfx.components.Shapes;
import struct.Ply;
import openings.OpeningTree;
import dict.Dictionary;
import struct.PieceType;
import struct.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import openfl.text.TextField;
import openfl.display.Sprite;

//TODO: Move to struct
enum Outcome
{
    Mate;
    Breakthrough;
    Resign;
    Abandon;
    DrawAgreement;
    Repetition;
    NoProgress;
    Timeout;
    Abort;
}

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/gameinfobox.xml'))
class GameInfoBox extends Card implements IGameBoardObserver implements INetObserver
{
    private var timeControlText:String;
    private var resolutionText:String;

    private var openingTree:OpeningTree;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(fromI, toI, fromJ, toJ, morphInto):
                var ply:Ply = new Ply();
                ply.from = new IntPoint(fromI, fromJ);
                ply.to = new IntPoint(toI, toJ);
                ply.morphInto = morphInto == null? null : PieceType.createByName(morphInto);
                accountMove(ply);
            case Rollback(plysToUndo):
                revertPlys(plysToUndo);
            case GameEnded(winner_color, reason):
                changeResolution(GameLogParser.decodeOutcome(reason), PieceColor.createByName(winner_color));
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        switch event 
        {
            case ContinuationMove(ply, plyStr, performedBy):
                accountMove(ply);
            default:
        }
    }

    private function actualize(parsedData:GameLogParserOutput)
    {
        if (parsedData.timeControl != null)
            setTimeControl(parsedData.timeControl);

        if (parsedData.outcome != null)
            changeResolution(parsedData.outcome, parsedData.winnerColor);

        for (ply in parsedData.movesPlayed)
            accountMove(ply);

        refreshShortInfo();
    }

    private function changeResolution(outcome:Outcome, winner:Null<PieceColor>) 
    {
        resolutionText = switch outcome 
        {
            case Mate: Dictionary.getPhrase(RESOLUTION_MATE) + ' • ' + dict.Utils.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
            case Breakthrough: Dictionary.getPhrase(RESOLUTION_BREAKTHROUGH) + ' • ' + dict.Utils.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
            case Resign: dict.Utils.getColorName(opposite(winner)) + Dictionary.getPhrase(RESOLUTION_RESIGN);
            case Abort: Dictionary.getPhrase(RESOLUTION_ABORT);
            case Abandon: dict.Utils.getColorName(opposite(winner)) + Dictionary.getPhrase(RESOLUTION_DISCONNECT);
            case DrawAgreement: Dictionary.getPhrase(RESOLUTION_AGREEMENT);
            case Repetition: Dictionary.getPhrase(RESOLUTION_REPETITON);
            case NoProgress: Dictionary.getPhrase(RESOLUTION_HUNDRED);
            case Timeout: Dictionary.getPhrase(RESOLUTION_TIMEOUT) + ' • ' + dict.Utils.getColorName(winner) + Dictionary.getPhrase(RESOLUTION_WINNER_POSTFIX);
        }
        refreshShortInfo();
    }

    private function setTimeControl(timeControl:TimeControl) 
    {
        timeControlText = timeControl.toString();
        refreshShortInfo();
    }

    private function accountMove(ply:Ply)
    {
        if (!openingTree.currentNode.terminal)
        {
            openingTree.makeMove(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
            openingTF.text = openingTree.currentNode.name;
        }
    }

    private function revertPlys(cnt:Int) 
    {
        openingTree.revertMoves(cnt);
        openingTF.text = openingTree.currentNode.name;
    }

    private function refreshShortInfo() 
    {
        if (timeControlText == "")
            shortInfoTF.text = resolutionText;
        else if (resolutionText == "")
            shortInfoTF.text = timeControlText;
        else
            shortInfoTF.text = timeControlText + " • " +  resolutionText;
    }

    public function new(width:Float, height:Float, timeControl:Null<TimeControl>, whiteLogin:String, blackLogin:String, ?actualizationData:GameLogParserOutput) 
    {
        super();
        this.width = width;
        this.height = height;

        openingTree = new OpeningTree();

        opponentsTF.text = '$whiteLogin vs $blackLogin';
        openingTF.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);

        resolutionText = Dictionary.getPhrase(RESOLUTION_NONE);
        timeControlText = "";
        if (timeControl != null)
            setTimeControl(timeControl);
        
        if (actualizationData != null)
            actualize(actualizationData);
        else
            refreshShortInfo();
    }
}