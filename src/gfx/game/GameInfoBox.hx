package gfx.game;

import net.shared.board.Situation;
import net.shared.board.RawPly;
import utils.SpecialChar;
import net.shared.EloValue;
import GlobalBroadcaster.GlobalEvent;
import gfx.profile.simple_components.PlayerLabel;
import net.shared.TimeControlType;
import dict.Utils;
import assets.Paths;
import net.EventProcessingQueue.INetObserver;
import gameboard.GameBoard.IGameBoardObserver;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gameboard.GameBoard.GameBoardEvent;
import net.shared.ServerEvent;
import utils.TimeControl;
import haxe.ui.containers.Card;
import haxe.ui.containers.VBox;
import openings.OpeningTree;
import dict.Dictionary;
import net.shared.PieceType;
import net.shared.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import net.shared.Outcome;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/live/gameinfobox.xml'))
class GameInfoBox extends Card implements IGameBoardObserver implements INetObserver
{
    private var openingTree:Null<OpeningTree> = null;
    private var movesAfterTerminalOpeningNode:Int = 0;

    private var whitePlayerLabel:PlayerLabel;
    private var crossSign:Label;
    private var blackPlayerLabel:PlayerLabel;

    private var renderedForWidth:Float = 0;

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(ply, _):
                accountMove(ply);
            case Rollback(plysToUndo, _):
                revertPlys(plysToUndo);
            case GameEnded(outcome, _, _, _):
                resolution.text = Utils.getResolution(outcome);
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

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case FollowedPlayerUpdated(followedLogin):
                if (whitePlayerLabel.playerRef == followedLogin.toLowerCase())
                    markFollowedPlayer(White);
                else if (blackPlayerLabel.playerRef == followedLogin.toLowerCase())
                    markFollowedPlayer(Black);
                else
                    markFollowedPlayer(null);
            default:
        }
    }

    private function accountMove(ply:RawPly)
    {
        if (openingTree == null)
            return;

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
        if (openingTree == null)
            return;

        if (movesAfterTerminalOpeningNode < cnt)
        {
            openingTree.revertMoves(cnt - movesAfterTerminalOpeningNode);
            opening.text = openingTree.currentNode.name;
            movesAfterTerminalOpeningNode = 0;
        }
        else
            movesAfterTerminalOpeningNode -= cnt;
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

        imagebox.width = this.width / 5;
        imagebox.height = this.width / 5;
        ResponsiveToolbox.fitComponent(timeControlIcon);

        var oppStyle = opponentsBox.customStyle.clone();
        oppStyle.marginLeft = this.width / 70;
        opponentsBox.customStyle = oppStyle;

        var wlStyle = whitePlayerLabel.customStyle.clone();
        wlStyle.fontSize = this.width * 17 / 350;
        whitePlayerLabel.customStyle = wlStyle;

        var crossStyle = crossSign.customStyle.clone();
        crossStyle.fontSize = this.width * 20 / 350;
        crossSign.customStyle = crossStyle;

        var blStyle = blackPlayerLabel.customStyle.clone();
        blStyle.fontSize = this.width * 17 / 350;
        blackPlayerLabel.customStyle = blStyle;

        var opStyle = opening.customStyle.clone();
        opStyle.fontSize = this.width / 25;
        opStyle.marginTop = this.width / 35;
        opening.customStyle = opStyle;

        renderedForWidth = this.width;
        return b;
    }

    private function fillOpponentsBox(whiteRef:String, blackRef:String, playerElos:Null<Map<PieceColor, EloValue>>)
    {
        var whiteELO = playerElos != null? playerElos[White] : null;
        var blackELO = playerElos != null? playerElos[Black] : null;

        whitePlayerLabel = new PlayerLabel(Exact(20), whiteRef, whiteELO, true);
        whitePlayerLabel.horizontalAlign = "center";

        crossSign = new Label();
        crossSign.text = "⚔";
        crossSign.customStyle = {fontSize: 20, fontBold: true, horizontalAlign: "center"};

        blackPlayerLabel = new PlayerLabel(Exact(20), blackRef, blackELO, true);
        blackPlayerLabel.horizontalAlign = "center";

        opponentsBox.addComponent(whitePlayerLabel);
        opponentsBox.addComponent(crossSign);
        opponentsBox.addComponent(blackPlayerLabel);
    }

    private function initNewGame(whiteRef:String, blackRef:String, playerElos:Null<Map<PieceColor, EloValue>>, timeControl:TimeControl, startingSituation:Situation, startDatetime:Date)
    {
        var tcType:TimeControlType = timeControl.getType();

        var separator:String = " " + SpecialChar.Dot + " ";
        if (tcType == Correspondence)
            matchParameters.text = Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME);
        else
            matchParameters.text = timeControl.toString() + separator + tcType.getName();

        datetime.text = DateTools.format(startDatetime, "%d.%m.%Y %H:%M:%S");
        resolution.text = Utils.getResolution(null);
        fillOpponentsBox(whiteRef, blackRef, playerElos);
        timeControlIcon.resource = Paths.timeControl(tcType);

        if (startingSituation.isDefaultStarting())
        {
            this.openingTree = new OpeningTree();
            opening.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);
        }
        else
            opening.text = Dictionary.getPhrase(CUSTOM_STARTING_POSITION);
    }

    private function initActualizedGame(parsedData:GameLogParserOutput)
    {
        var tcType:TimeControlType = parsedData.timeControl.getType();

        var separator:String = " " + SpecialChar.Dot + " ";
        if (tcType == Correspondence)
            matchParameters.text = Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME);
        else
            matchParameters.text = parsedData.timeControl.toString() + separator + tcType.getName();

        fillOpponentsBox(parsedData.whiteRef, parsedData.blackRef, parsedData.elo);
        resolution.text = Utils.getResolution(parsedData.outcome);
        timeControlIcon.resource = Paths.timeControl(tcType);

        if (parsedData.datetime != null)
            datetime.text = DateTools.format(parsedData.datetime, "%d.%m.%Y %H:%M:%S");

        if (parsedData.startingSituation.isDefaultStarting())
        {
            this.openingTree = new OpeningTree();
            opening.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);
        }
        else
            opening.text = Dictionary.getPhrase(CUSTOM_STARTING_POSITION);

        for (ply in parsedData.movesPlayed)
            accountMove(ply);
    }

    private function markFollowedPlayer(color:Null<PieceColor>)
    {
        switch color 
        {
            case null:
                watchingLabel.hidden = true;
            case White:
                watchingLabel.hidden = false;
                watchingLabel.text = Dictionary.getPhrase(LIVE_WATCHING_LABEL_TEXT(Utils.playerRef(whitePlayerLabel.playerRef)));
            case Black:
                watchingLabel.hidden = false;
                watchingLabel.text = Dictionary.getPhrase(LIVE_WATCHING_LABEL_TEXT(Utils.playerRef(blackPlayerLabel.playerRef)));
        }
    }

    public function init(constructor:LiveGameConstructor)
    {
        switch constructor 
        {
            case New(whiteRef, blackRef, playerElos, timeControl, startingSituation, startDatetime):
                initNewGame(whiteRef, blackRef, playerElos, timeControl, startingSituation, startDatetime);
            case Ongoing(parsedData, _, followedPlayerLogin):
                initActualizedGame(parsedData);
                if (followedPlayerLogin != null)
                    markFollowedPlayer(parsedData.getParticipantColor(followedPlayerLogin));
            case Past(parsedData, _):
                initActualizedGame(parsedData);
        }
    }

    public function new() 
    {
        super();
    }
}