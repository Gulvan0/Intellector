package tests.ui.game;

import net.ServerEvent;
import struct.PieceColor;
import struct.Situation;
import struct.Ply;
import serialization.PlyDeserializer;
import js.Browser;
import gameboard.GameBoard.GameBoardEvent;
import serialization.GameLogParser;
import serialization.GameLogParser.GameLogParserOutput;
import gfx.game.Sidebox;
import openfl.display.Sprite;

class TSidebox extends Sprite
{
    private var sidebox:Sidebox;

    private var testGamelogParserOutput:GameLogParserOutput;

    @steps(9)
    private function _seq_initializationTypes(i:Int) 
    {
        removeChild(sidebox);

        switch i
        {
            case 0: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", White);
            case 1: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", Black);
            case 2: sidebox = new Sidebox(Black, 600, 5, "PlayerWhite", "PlayerBlack", Black);
            case 3: sidebox = new Sidebox(Black, 600, 5, "PlayerWhite", "PlayerBlack", White);
            case 4: sidebox = new Sidebox(White, 600, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 5: sidebox = new Sidebox(null, 600, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 6: sidebox = new Sidebox(null, 80, 5, "PlayerWhite", "PlayerBlack", Black, testGamelogParserOutput);
            case 7: sidebox = new Sidebox(White, 600, 20, "PlayerWhite", "PlayerBlack", White);
            case 8: sidebox = new Sidebox(White, 600, 0, "PlayerWhite", "PlayerBlack", White);
        }

        addChild(sidebox);
    }

    private function _act_ContinuationMove() 
    {
        var resp:String = Browser.window.prompt("Input the serialized ply");
        if (resp == null)
            return;
        var ply:Ply = PlyDeserializer.deserialize(resp);
        var situation:Situation = Situation.starting();
        var plyStr:String = ply.toNotation(situation);
        var performedBy:PieceColor = situation.get(ply.from).color;

        sidebox.handleGameBoardEvent(ContinuationMove(ply, plyStr, performedBy));
    }

    private var _checks_ContinuationMove:Array<String> = [
        "First n moves are added correctly considering situation is always starting",
        "Overflow is handled correctly"
    ];

    //TODO: To be used in RightPanel tests, not there
    /*private function _act_SubsequentMove() 
    {
        var resp:String = Browser.window.prompt("Input the serialized ply");
        if (resp == null)
            return;
        var ply:Ply = PlyDeserializer.deserialize(resp);
        var situation:Situation = Situation.starting();
        var plyStr:String = ply.toNotation(situation);
        var performedBy:PieceColor = situation.get(ply.from).color;

        sidebox.handleGameBoardEvent(SubsequentMove(plyStr, performedBy));
    }

    private var _checks_SubsequentMove:Array<String> = [
        "No reaction"
    ];

    private function _act_BranchingMove() 
    {
        var resp:String = Browser.window.prompt("Input the serialized ply");
        if (resp == null)
            return;
        var ply:Ply = PlyDeserializer.deserialize(resp);
        var situation:Situation = Situation.starting();
        var plyStr:String = ply.toNotation(situation);
        var performedBy:PieceColor = situation.get(ply.from).color;

        var resp2:String = Browser.window.prompt("Input the pointer (number of moves before the specified ply)");
        if (resp2 == null)
            return;
        var pointer:Int = Std.parseInt(resp2);

        var resp3:String = Browser.window.prompt("Input the current branch's length (total number of moves)");
        if (resp3 == null)
            return;
        var branchLength:Int = Std.parseInt(resp3);

        sidebox.handleGameBoardEvent(BranchingMove(ply, plyStr, performedBy, pointer, branchLength));
    }

    private var _checks_BranchingMove:Array<String> = [
        "Ply history gets cut after specified number of plys, then, new ply is appended",
        "ContinuationMove works correctly after BranchingMove",
        "2+ successive BranchingMove's work correctly"
    ];

    private function _act_SituationEdited() 
    {
        sidebox.handleGameBoardEvent(SituationEdited(Situation.randomPlay(3)));
    }

    private var _checks_SituationEdited:Array<String> = [
        "No reaction"
    ];*/

    private function _act_offerEvent() 
    {
        var resp:String = Browser.window.prompt("Input the event name");
        if (resp == null)
            return;
        sidebox.handleNetEvent(ServerEvent.createByName(resp));
    }

    private var _checks_offerEvent:Array<String> = [
        "DrawOffered => click 'accept'",
        "DrawOffered => click 'decline'",
        "TakebackOffered => click 'accept'",
        "TakebackOffered => click 'decline'",
        "DrawOffered => DrawCancelled",
        "DrawOffered => click 'offer draw'",
        "TakebackOffered => TakebackCancelled",
        "TakebackOffered => click 'offer takeback'",
        "click 'offer draw' => DrawAccepted",
        "click 'offer draw' => DrawDeclined",
        "click 'offer takeback' => TakebackAccepted",
        "click 'offer takeback' => TakebackDeclined",
        "TakebackOffered => TakebackCancelled",
        "TakebackOffered => click 'offer takeback'"
    ];

    private function _act_GameEnded() 
    {
        sidebox.handleNetEvent(GameEnded('w', 'mat'));
    }

    private var _checks_GameEnded:Array<String> = [
        "Timers are stopped",
        "5 or 6: action button set is changed"
    ];

    private function _act_RollbackThree() 
    {
        sidebox.handleNetEvent(Rollback(3));
    }

    private var _checks_RollbackThree:Array<String> = [
        "History cut correctly",
        "ContinuationMove processed correctly after a rollback"
    ];

    private function _act_correctTime() 
    {
        var ts = Date.now().getTime() - 200;
        sidebox.handleNetEvent(TimeCorrection(124, 9, ts, 'b'));
    }

    //TODO: Way to check white's crit
    //TODO: Split 2/3 based on hyperbullet flag
    //TODO: Same for white
    //TODO: Check styling depending on turnColor
    //TODO: Maybe somehow elicit that spectator's sidebox should be checked separately
    //TODO: Checking natural lowTime for both sides + spectator
    //TODO: Finish clock's todo's (also check other tested components)
    //TODO: Check AddTime effect overall
    //TODO: Check AddTime requested by player workaround
    private var _checks_correctTime:Array<String> = [
        "Time set to 2:04 white / 0:09.800 black",
        "2 or 3: black timer critical + no sound",
        "others: both timers not critical + no sound",
        "Everything above still holds for inverse orientation"
    ];

    //TODO: Checks for buttons (their sets & what happend when pressed)

    //TODO: Separate makeMove testing for enemy moves - they need board's situation + styling and timers change

    //TODO: Checklists for each initialization type

    //TODO: Subscribe to Sidebox events

    public function new()
    {
        super();
        testGamelogParserOutput = GameLogParser.parse("6620;\n3020Aggressor;1514;\n");
    }
}