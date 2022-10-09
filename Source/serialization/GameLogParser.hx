package serialization;

import net.shared.EloValue;
import utils.TimeControl;
import net.shared.Outcome;
import net.shared.PieceColor;
import struct.Ply;
import struct.Situation;
import net.shared.PieceType;
import struct.Hex;
import struct.HexTransform;
import struct.ReversiblePly;
import dict.*;
using StringTools;
using Lambda;

enum ChatEntry
{
    PlayerMessage(author:PieceColor, text:String);
    Log(text:String);
}

class GameLogParserOutput
{
    public var timeControl:TimeControl = new TimeControl(0, 0);
    public var whiteLogin:Null<String>;
    public var blackLogin:Null<String>;
    public var elo:Null<Map<PieceColor, EloValue>>;
    public var outcome:Null<Outcome>;
    public var msLeftWhenEnded:Null<Map<PieceColor, Int>>;
    public var movesPlayed:Array<Ply> = [];
    public var chatEntries:Array<ChatEntry> = [];
    public var datetime:Null<Date>;
    public var startingSituation:Situation = Situation.starting();
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
            currentSituation.makeMove(ply, true);
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

    public function getParticipantColor(participantLogin:String)
    {
        if (whiteLogin.toLowerCase() == participantLogin.toLowerCase())
            return White;
        else if (blackLogin.toLowerCase() == participantLogin.toLowerCase())
            return Black;
        else
            return null;
    }

    public function getPlayerColor():Null<PieceColor>
    {
        if (LoginManager.isPlayer(whiteLogin))
            return White;
        else if (LoginManager.isPlayer(blackLogin))
            return Black;
        else
            return null;
    }

    public function isPlayerParticipant():Bool 
    {
        return getPlayerColor() != null;
    }

    public function getPlayerOpponentLogin():Null<String>
    {
        if (LoginManager.isPlayer(whiteLogin))
            return blackLogin;
        else if (LoginManager.isPlayer(blackLogin))
            return whiteLogin;
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

        var ply:Ply = PlySerializer.deserialize(splitted[0]);
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
                var playerLogins:Array<String> = args[0].split(":");
                parserOutput.whiteLogin = playerLogins[0];
                parserOutput.blackLogin = playerLogins[1];
            case "e":
                parserOutput.elo = [White => decodeELO(args[0]), Black => decodeELO(args[1])];
            case "D":
                parserOutput.datetime = Date.fromTime(Std.parseInt(args[0]) * 1000);
            case "L":
                parserOutput.msLeftWhenEnded = [White => Std.parseInt(args[0]), Black => Std.parseInt(args[1])];
            case "S":
                parserOutput.startingSituation = Situation.fromSIP(args[0]);
            case "T":
                parserOutput.timeControl = new TimeControl(Std.parseInt(args[0]), Std.parseInt(args[1]));
            case "C":
                parserOutput.chatEntries.push(PlayerMessage(decodeColor(args[0]), args[1]));
            case "R":
                parserOutput.outcome = decodeOutcome(args[0], args[1]);
            case "E":
                var eventCode:String = args[0];
                var logMessage:String = switch eventCode 
                {
                    case "dcn":
                        Utils.getPlayerDisconnectedMessage(decodeColor(args[1]));
                    case "rcn":
                        Utils.getPlayerReconnectedMessage(decodeColor(args[1]));
                    case "dof":
                        Dictionary.getPhrase(DRAW_OFFERED_MESSAGE);
                    case "dca":
                        Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE);
                    case "dac":
                        Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE);
                    case "dde":
                        Dictionary.getPhrase(DRAW_DECLINED_MESSAGE);
                    case "tof":
                        Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE);
                    case "tca":
                        Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE);
                    case "tac":
                        Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE);
                    case "tde":
                        Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE);
                    default:
                        "";
                }
                parserOutput.chatEntries.push(Log(logMessage));
        }        
    }

    private static function decodeELO(str:String):EloValue 
    {
        if (str == "n")
            return None;
        else if (str.startsWith("p"))
            return Provisional(Std.parseInt(str.substr(1)));
        else 
            return Normal(Std.parseInt(str));
    }

    private static function decodeOutcome(winnerColorCode:String, reasonCode:String):Null<Outcome>
    {
        var winnerColor:PieceColor = decodeColor(winnerColorCode);
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