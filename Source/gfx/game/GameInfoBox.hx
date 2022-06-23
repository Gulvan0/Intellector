package gfx.game;

import format.SVG;
import struct.ActualizationData;
import openfl.display.Shape;
import utils.AssetManager;
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
import struct.Outcome;

@:build(haxe.ui.macros.ComponentMacros.build('Assets/layouts/gameinfobox.xml'))
class GameInfoBox extends Card implements IGameBoardObserver implements INetObserver
{
    private var openingTree:OpeningTree;
    private var movesAfterTerminalOpeningNode:Int = 0;

    private var timeControlIcon:SVG;
    private var renderedForWidth:Float = 0;

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
                changeResolution(GameLogParser.decodeOutcome(reason), GameLogParser.decodeColor(winner_color));
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

    private function changeResolution(outcome:Outcome, winner:Null<PieceColor>) 
    {
        var outcomeStr:String = switch outcome 
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
        resolution.text = outcomeStr;
    }

    private function accountMove(ply:Ply)
    {
        if (!openingTree.currentNode.terminal)
        {
            openingTree.makeMove(ply.from.i, ply.from.j, ply.to.i, ply.to.j, ply.morphInto);
            opening.text = openingTree.currentNode.name;
        }
        else
            movesAfterTerminalOpeningNode++;
    }

    private function revertPlys(cnt:Int) 
    {
        if (movesAfterTerminalOpeningNode < cnt)
        {
            openingTree.revertMoves(cnt - movesAfterTerminalOpeningNode);
            opening.text = openingTree.currentNode.name;
            movesAfterTerminalOpeningNode = 0;
        }
        else
            movesAfterTerminalOpeningNode -= cnt;
    }

    public static function constructFromActualizationData(data:ActualizationData):GameInfoBox
    {
        var infobox:GameInfoBox = new GameInfoBox(data.logParserOutput.timeControl, data.logParserOutput.whiteLogin, data.logParserOutput.blackLogin);

        var parsedData = data.logParserOutput;

        if (parsedData.outcome != null)
            infobox.changeResolution(parsedData.outcome, parsedData.winnerColor);

        if (parsedData.datetime != null)
            infobox.datetime.text = DateTools.format(parsedData.datetime, "%d.%m.%Y %H:%M:%S");

        for (ply in parsedData.movesPlayed)
            infobox.accountMove(ply);

        return infobox;
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();

        if (renderedForWidth == this.width)
            return b;

        var thisStyle = this.customStyle.clone();
        thisStyle.verticalSpacing = this.width / 70;
        thisStyle.padding = this.width * 15 / 350;
        this.customStyle = thisStyle;

        var mpStyle = matchParameters.customStyle.clone();
        mpStyle.fontSize = this.width * 16 / 350;
        matchParameters.customStyle = mpStyle;

        var dtStyle = datetime.customStyle.clone();
        dtStyle.fontSize = this.width * 12 / 350;
        datetime.customStyle = dtStyle;

        var resStyle = resolution.customStyle.clone();
        resStyle.fontSize = this.width / 25;
        resolution.customStyle = resStyle;

        imagebox.removeAllComponents();
        imagebox.width = this.width / 5;
        imagebox.height = this.width / 5;

        var tcIcon = AssetManager.getSVGComponent(timeControlIcon, 0, 0, Math.floor(imagebox.width), Math.floor(imagebox.height));
        tcIcon.horizontalAlign = 'center';
        tcIcon.verticalAlign = 'top';
        imagebox.addComponent(tcIcon);

        var oppStyle = opponentsBox.customStyle.clone();
        oppStyle.marginLeft = this.width / 70;
        opponentsBox.customStyle = oppStyle;

        var wlStyle = whiteLoginLabel.customStyle.clone();
        wlStyle.fontSize = this.width * 17 / 350;
        whiteLoginLabel.customStyle = wlStyle;

        var crossStyle = crossSign.customStyle.clone();
        crossStyle.fontSize = this.width * 20 / 350;
        crossSign.customStyle = crossStyle;

        var blStyle = blackLoginLabel.customStyle.clone();
        blStyle.fontSize = this.width * 17 / 350;
        blackLoginLabel.customStyle = blStyle;

        var opStyle = opening.customStyle.clone();
        opStyle.fontSize = this.width / 25;
        opStyle.marginTop = this.width / 35;
        opening.customStyle = opStyle;

        renderedForWidth = this.width;
        return b;
    }

    public function new(timeControl:TimeControl, whiteLogin:String, blackLogin:String) 
    {
        super();
        this.openingTree = new OpeningTree();

        var tcType:TimeControlType = timeControl.getType();

        resolution.text = Dictionary.getPhrase(RESOLUTION_NONE);
        matchParameters.text = tcType == Correspondence? "Correspondence" : timeControl.toString() + " • " + tcType.getName();
        whiteLoginLabel.text = whiteLogin;
        blackLoginLabel.text = blackLogin;
        opening.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);

        timeControlIcon = AssetManager.timeControlIcons[tcType];
    }
}