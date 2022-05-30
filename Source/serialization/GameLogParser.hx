package serialization;

import net.LoginManager;
import utils.TimeControl;
import gfx.game.GameInfoBox.Outcome;
import struct.PieceColor;
import struct.Ply;
import struct.Situation;
import struct.PieceType;
import struct.Hex;
import struct.HexTransform;
import struct.ReversiblePly;
import dict.*;
using StringTools;

enum ChatEntry
{
    PlayerMessage(author:PieceColor, text:String);
    Log(text:String);
}

class GameLogParserOutput
{
    public var timeControl:Null<TimeControl>;
    public var whiteLogin:Null<String>;
    public var blackLogin:Null<String>;
    public var outcome:Null<Outcome>;
    public var winnerColor:Null<PieceColor>;
    public var movesPlayed:Array<Ply> = [];
    public var chatEntries:Array<ChatEntry> = [];
    public var datetime:Null<Date>;
    public var currentSituation:Situation;

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
        currentSituation = Situation.starting();
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
            {
                var ply:Ply = PlySerializer.deserialize(trimmedEntry);
                parserOutput.movesPlayed.push(ply);
                parserOutput.currentSituation = parserOutput.currentSituation.makeMove(ply);
            }
        }
        return parserOutput;
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
                parserOutput.datetime = Date.fromTime(Std.parseFloat(args[0]));
            case "T":
                parserOutput.timeControl = new TimeControl(Std.parseInt(args[0]), Std.parseInt(args[1]));
            case "C":
                parserOutput.chatEntries.push(PlayerMessage(decodeColor(args[0]), args[1]));
            case "R":
                parserOutput.winnerColor = decodeColor(args[0]);
                parserOutput.outcome = decodeOutcome(args[1]);
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

    public static function decodeOutcome(reasonCode:String):Null<Outcome>
    {
        return switch reasonCode 
        {
            case "mat": Mate;
            case "bre": Breakthrough;
            case "res": Resign;
            case "tim": Timeout;
            case "aba": Abandon;
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