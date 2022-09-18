package serialization;

import utils.TimeControl;
import struct.Outcome;
import struct.PieceColor;
import struct.Ply;
import struct.Situation;
import struct.PieceType;
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
    public var outcome:Null<Outcome>;
    public var msLeftWhenEnded:Null<Map<PieceColor, Int>>;
    public var movesPlayed:Array<Ply> = [];
    public var chatEntries:Array<ChatEntry> = [];
    public var datetime:Null<Date>;
    public var startingSituation:Situation = Situation.starting();
    /**
        NOTE: getSecsLeftAfterMove() provides a more convenient way of retrieving the data.

        i-th element determines the amount of milliseconds a player had after making the (i+1)-th move, including increment.
        For example, if white starts, 0th element corresponds to a time left for White after White made the first move.
        In the same way, 1th element equals the time Black had after making the second move (again, provided White starts).
        If, for some reason, there's data missing for some of the moves, the respective elements will be null.
    **/
    public var msLeftOnMove:Array<Null<Int>> = [];
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

        msPerMoveDataAvailable = msLeftOnMove.exists(x -> x != null);
    }

    public function getSecsLeftAfterMove(side:PieceColor, plyNum:Int):Null<Float>
    {
        if (!msPerMoveDataAvailable)
            return null;

        if (plyNum == moveCount && msLeftWhenEnded != null)
            return msLeftWhenEnded[side] / 1000;

        var isOwnMove:Bool;
        if (side == startingSituation.turnColor)
            isOwnMove = plyNum % 2 == 1;
        else
            isOwnMove = plyNum % 2 == 0;

        var index:Int = isOwnMove? plyNum - 1 : plyNum - 2;
        while (index >= 0)
        {
            var msLeft:Null<Int> = msLeftOnMove[index];
            if (msLeft != null)
                return msLeft / 1000;
            else
                index -= 2;
        }

        return timeControl.startSecs;
    }

    public function gameEnded():Bool
    {
        return outcome != null;
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
        var plyStr:String;

        if (trimmedEntry.contains("/"))
        {
            var splitted:Array<String> = trimmedEntry.split("/");
            plyStr = splitted[0];
            parserOutput.msLeftOnMove.push(Std.parseInt(splitted[1]));
        }
        else
        {
            plyStr = trimmedEntry;
            parserOutput.msLeftOnMove.push(null);
        }

        var ply:Ply = PlySerializer.deserialize(plyStr);
        parserOutput.movesPlayed.push(ply);
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

    public static function decodeOutcome(winnerColorCode:String, reasonCode:String):Null<Outcome>
    {
        var winnerColor:PieceColor = decodeColor(winnerColorCode);
        return switch reasonCode 
        {
            case "mat": Mate(winnerColor);
            case "bre": Breakthrough(winnerColor);
            case "res": Resign(winnerColor);
            case "tim": Timeout(winnerColor);
            case "aba": Abandon(winnerColor);
            case "rep": Repetition;
            case "100": NoProgress;
            case "agr": DrawAgreement;
            case "abo": Abort; 
            default: null;
        }
    }

    public static function decodeColor(letter:String):Null<PieceColor> 
    {
        return switch letter 
        {
            case "w": White;
            case "b": Black;
            default: null;
        }
    }
}