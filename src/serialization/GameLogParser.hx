package serialization;

import net.shared.utils.PlayerRef;
import net.shared.converters.PlySerializer;
import net.shared.board.RawPly;
import net.shared.EloValue;
import utils.TimeControl;
import net.shared.Outcome;
import net.shared.PieceColor;
import dict.*;
import net.shared.board.Situation;
using StringTools;
using Lambda;

enum ChatEntry
{
    PlayerMessage(author:PieceColor, text:String);
    Log(text:String);
}

class GameLogParserOutput
{
    public var timeControl:TimeControl = TimeControl.correspondence();
    public var whiteRef:String;
    public var blackRef:String;
    public var elo:Null<Map<PieceColor, EloValue>>;
    public var outcome:Null<Outcome>;
    public var msLeftWhenEnded:Null<Map<PieceColor, Int>>;
    public var movesPlayed:Array<RawPly> = [];
    public var chatEntries:Array<ChatEntry> = [];
    public var datetime:Null<Date>;
    public var startingSituation:Situation = Situation.defaultStarting();
    public var msLeftOnMove:Map<PieceColor, Array<Null<Int>>> = [White => [], Black => []];
    public var msPerMoveDataAvailable:Bool;

    public var currentSituation:Situation;
    public var moveCount:Int;

    public function computeDerived()
    {
        moveCount = 0;
        currentSituation = startingSituation.copy();

        for (ply in movesPlayed)
        {
            moveCount++;
            currentSituation.performRawPly(ply);
        }

        msPerMoveDataAvailable = msLeftOnMove[White].exists(x -> x != null) || msLeftOnMove[Black].exists(x -> x != null);
    }

    public function getSecsLeftAfterMove(side:PieceColor, plyNum:Int):Null<Float>
    {
        if (!msPerMoveDataAvailable)
            return null;

        if (plyNum == moveCount && msLeftWhenEnded != null)
            return msLeftWhenEnded[side] / 1000;

        var index:Int = plyNum - 1;
        while (index >= 0)
        {
            var msLeft:Null<Int> = msLeftOnMove[side][index];
            if (msLeft != null)
                return msLeft / 1000;
            else
                index--;
        }

        return timeControl.startSecs;
    }

    public function gameEnded():Bool
    {
        return outcome != null;
    }

    public function isRated():Bool
    {
        return elo != null;
    }

    public function getParticipantColor(participantRef:String):Null<PieceColor>
    {
        if (whiteRef.toLowerCase() == participantRef.toLowerCase())
            return White;
        else if (blackRef.toLowerCase() == participantRef.toLowerCase())
            return Black;
        else
            return null;
    }

    public function getPlayerColor():Null<PieceColor>
    {
        if (LoginManager.isPlayer(whiteRef))
            return White;
        else if (LoginManager.isPlayer(blackRef))
            return Black;
        else
            return null;
    }

    public function isPlayerParticipant():Bool 
    {
        return getPlayerColor() != null;
    }

    public function getPlayerOpponentRef():Null<PlayerRef>
    {
        if (LoginManager.isPlayer(whiteRef))
            return blackRef;
        else if (LoginManager.isPlayer(blackRef))
            return whiteRef;
        else
            return null;
    }

    public function new()
    {

    }
}

class GameLogParser 
{
    public static function parse(log:String):GameLogParserOutput
    {
        var parserOutput:GameLogParserOutput = new GameLogParserOutput();

        for (entry in log.split(";"))
        {
            var trimmedEntry = entry.trim();
            if (trimmedEntry.charAt(0) == "#")
                processSpecialEntry(trimmedEntry.charAt(1), trimmedEntry.substr(3), parserOutput);
            else if (trimmedEntry.length >= 4)
                processNormalEntry(trimmedEntry, parserOutput);
        }

        parserOutput.computeDerived();

        return parserOutput;
    }

    private static function processNormalEntry(trimmedEntry:String, parserOutput:GameLogParserOutput)
    {
        var splitted:Array<String> = trimmedEntry.split("/");

        var ply:RawPly = PlySerializer.deserialize(splitted[0]);
        parserOutput.movesPlayed.push(ply);

        parserOutput.msLeftOnMove[White].push(Std.parseInt(splitted[1]));
        parserOutput.msLeftOnMove[Black].push(Std.parseInt(splitted[2]));
    }

    private static function processSpecialEntry(typeCode:String, body:String, parserOutput:GameLogParserOutput) 
    {
        var args:Array<String> = body.split("/");
        switch typeCode
        {
            case "P":
                parserOutput.whiteRef = args[0];
                parserOutput.blackRef = args[1];
            case "e":
                parserOutput.elo = [White => deserialize(args[0]), Black => deserialize(args[1])];
            case "D":
                parserOutput.datetime = Date.fromTime(Std.parseFloat(args[0]) * 1000);
            case "L":
                parserOutput.msLeftWhenEnded = [White => Std.parseInt(args[0]), Black => Std.parseInt(args[1])];
            case "S":
                parserOutput.startingSituation = Situation.deserialize(args[0]);
            case "T":
                parserOutput.timeControl = new TimeControl(Std.parseInt(args[0]), Std.parseInt(args[1]));
            case "C":
                parserOutput.chatEntries.push(PlayerMessage(decodeColor(args[0]), args[1]));
            case "R":
                parserOutput.outcome = decodeOutcome(args[0], args[1]);
            case "E":
                var eventCode:String = args[0];
                var color:PieceColor = decodeColor(args[1]);
                var logMessage:Null<Phrase> = null;
                
                switch eventCode 
                {
                    case "dcn":
                        logMessage = PLAYER_DISCONNECTED_MESSAGE(color);
                    case "rcn":
                        logMessage = PLAYER_RECONNECTED_MESSAGE(color);
                    case "dof":
                        logMessage = DRAW_OFFERED_MESSAGE(color);
                    case "dca":
                        logMessage = DRAW_CANCELLED_MESSAGE(color);
                    case "dac":
                        logMessage = DRAW_ACCEPTED_MESSAGE(color);
                    case "dde":
                        logMessage = DRAW_DECLINED_MESSAGE(color);
                    case "tof":
                        logMessage = TAKEBACK_OFFERED_MESSAGE(color);
                    case "tca":
                        logMessage = TAKEBACK_CANCELLED_MESSAGE(color);
                    case "tac":
                        logMessage = TAKEBACK_ACCEPTED_MESSAGE(color);
                    case "tde":
                        logMessage = TAKEBACK_DECLINED_MESSAGE(color);
                    case "tad":
                        logMessage = TIME_ADDED_MESSAGE(color);
                    default:
                        "";
                }

                if (logMessage != null)
                    parserOutput.chatEntries.push(Log(Dictionary.getPhrase(logMessage)));
        }        
    }

    private static function decodeOutcome(winnerColorCode:String, reasonCode:String):Null<Outcome>
    {
        var winnerColor:Null<PieceColor> = decodeColor(winnerColorCode);
        return switch reasonCode 
        {
            case "mat": Decisive(Mate, winnerColor);
            case "bre": Decisive(Breakthrough, winnerColor);
            case "res": Decisive(Resign, winnerColor);
            case "tim": Decisive(Timeout, winnerColor);
            case "aba": Decisive(Abandon, winnerColor);
            case "rep": Drawish(Repetition);
            case "100": Drawish(NoProgress);
            case "agr": Drawish(DrawAgreement);
            case "abo": Drawish(Abort);
            case "unk": winnerColor != null? Decisive(Abandon, winnerColor) : Drawish(Abort);
            default: null;
        }
    }

    private static function decodeColor(letter:String):Null<PieceColor> 
    {
        return switch letter 
        {
            case "w": White;
            case "b": Black;
            default: null;
        }
    }
}