package tests.ui.game;

import net.LoginManager;
import struct.ActualizationData;
import utils.TimeControl;
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

    private function replaceSidebox(sb:Sidebox)
    {
        removeChild(sidebox);
        sidebox = sb;
        addChild(sidebox);
    }

    private function _act_scaled(i:Int) 
    {
        replaceSidebox(new Sidebox(White, new TimeControl(600, 5), "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
    }

    @steps(12)
    private function _seq_initialStates(i:Int) 
    {
        var shortTimeControl:TimeControl = new TimeControl(80, 5);
        var longTimeControl:TimeControl = new TimeControl(600, 5);
        switch i
        {
            case 0: replaceSidebox(new Sidebox(White, longTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 1: replaceSidebox(new Sidebox(Black, longTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 2: replaceSidebox(new Sidebox(null, longTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 3: replaceSidebox(new Sidebox(White, shortTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 4: replaceSidebox(new Sidebox(Black, shortTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 5: replaceSidebox(new Sidebox(null, shortTimeControl, "PlayerWhite", "PlayerBlack", White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 6: replaceSidebox(new Sidebox(White, longTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 7: replaceSidebox(new Sidebox(Black, longTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 8: replaceSidebox(new Sidebox(null, longTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 9: replaceSidebox(new Sidebox(White, shortTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 10: replaceSidebox(new Sidebox(Black, shortTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 11: replaceSidebox(new Sidebox(null, shortTimeControl, "PlayerWhite", "PlayerBlack", Black, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
        }
    }

    private var _checks_initialStates:Map<Int, Array<String>> = [
        -1 => ["Check login card positions", "Check button rows", "Check time on the clocks", "Check flipBoard effect (both login and time should swap)"],
        0 => ["Playing as white, 10:00 starting time, Watching white's POV"],
        1 => ["Playing as black, 10:00 starting time, Watching white's POV"],
        2 => ["Playing as spectator, 10:00 starting time, Watching white's POV"],
        3 => ["Playing as white, 01:20 starting time, Watching white's POV"],
        4 => ["Playing as black, 01:20 starting time, Watching white's POV"],
        5 => ["Playing as spectator, 01:20 starting time, Watching white's POV"],
        6 => ["Playing as white, 10:00 starting time, Watching black's POV"],
        7 => ["Playing as black, 10:00 starting time, Watching black's POV"],
        8 => ["Playing as spectator, 10:00 starting time, Watching black's POV"],
        9 => ["Playing as white, 01:20 starting time, Watching black's POV"],
        10 => ["Playing as black, 01:20 starting time, Watching black's POV"],
        11 => ["Playing as spectator, 01:20 starting time, Watching black's POV"]
    ];

    @steps(10)
    private function _seq_actualized(i:Int)
    {
        LoginManager.login = "PlayerBlack";

        var data0 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T80/5;\n");
        var data1 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T80/5;\n6620;\n");
        var data2 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T80/5;\n6620;\n3020Aggressor;\n");
        var data3 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T80/5;\n6620;\n3020Aggressor;\n1514;\n");

        switch i
        {
            case 0:
                replaceSidebox(Sidebox.constructFromActualizationData(data0, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 1:
                sidebox.makeMove("6620");
            case 2:
                sidebox.makeMove("3020Aggressor");
            case 3:
                sidebox.makeMove("1514");
            case 4:
                replaceSidebox(Sidebox.constructFromActualizationData(data1, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 5:
                sidebox.makeMove("3020Aggressor");
            case 6:
                sidebox.makeMove("1514");
            case 7:
                replaceSidebox(Sidebox.constructFromActualizationData(data2, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 8:
                sidebox.makeMove("1514");
            case 9:
                replaceSidebox(Sidebox.constructFromActualizationData(data3, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
        }
    }

    private var _checks_actualized:Map<Int, Array<String>> = [
        -1 => ["Navigator entries regenerate correctly", "Navigator entries are appended correctly"],
        0 => ["0 moves", "All timers are stopped", "White's card styled as MOVE", "'Resign' has abort tooltip", "'Resign' has abort question", "'Draw' disabled", "'Takeback' disabled"],
        1 => ["All timers are stopped", "White's card styled as WAIT", "Black's card styled as MOVE"],
        2 => ["White's timer starts running", "Black's timer is stopped", "Styles are inverted again", "'Resign' has resign tooltip", "'Resign' has resign question", "'Draw' enabled", "'Takeback' enabled"],
        3 => ["White's timer stops", "Black's timer starts running", "Styles are inverted again"],
        4 => ["1 move", "All timers are stopped", "Black's card styled as MOVE"],
        5 => ["White's timer starts running", "Black's timer is stopped", "Styles are inverted again"],
        6 => ["White's timer stops", "Black's timer starts running", "Styles are inverted again"],
        7 => ["2 moves", "White's timer starts running", "Black's timer is stopped", "White's card styled as MOVE"],
        8 => ["White's timer stops", "Black's timer starts running", "Styles are inverted again"],
        9 => ["3 moves", "White's timer is stopped", "Black's timer starts running", "Black's card styled as MOVE"],
    ];

    @steps(10)
    private function _seq_alerts(i:Int)
    {
        var data0 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T80/15;\n6620;\n3020Aggressor;\n");
        var data1 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T100/5;\n6620;\n3020Aggressor;\n");
        var data2 = new ActualizationData("#P|PlayerWhite:PlayerBlack;\n#T100/0;\n6620;\n3020Aggressor;\n");

        switch i
        {
            case 0:
                LoginManager.login = "PlayerWhite";
                replaceSidebox(Sidebox.constructFromActualizationData(data0, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 1:
                sidebox.makeMove("1514");
            case 2:
                sidebox.makeMove("1011");
            case 3:
                LoginManager.login = "PlayerBlack";
                replaceSidebox(Sidebox.constructFromActualizationData(data1, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 4:
                sidebox.makeMove("1514");
            case 5:
                LoginManager.login = "PlayerWhite";
                replaceSidebox(Sidebox.constructFromActualizationData(data1, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 6:
                sidebox.makeMove("1514");
            case 7:
                sidebox.makeMove("1011");
            case 8:
                LoginManager.login = "PlayerNone";
                replaceSidebox(Sidebox.constructFromActualizationData(data2, White, ab -> {trace(ab.getName());}, ps -> {trace(ps.getName());}));
            case 9:
                sidebox.makeMove("1514");
        }
    }

    private var _checks_alerts:Map<Int, Array<String>> = [
        0 => ["Decay normal->crit styling applied correctly (step right after)", "No sound alert (too fast control)"],
        1 => ["Replenish un-styling works correctly", "15 secs added", "(if stepped too late) Critical MOVE->WAIT works correctly", "Decay normal->crit not applied (not own)", "No sound alert (not own & too fast control)"],
        2 => ["(if stepped 0->1 too late) Critical WAIT->MOVE works correctly", "Timer becomes precise at 10sec", "Timer stops at zero"],
        3 => ["No style change due to decay (Next step when timer reaches 00:09)", "No sound alert (not own)"],
        4 => ["Timer becomes less precise on >10sec", "Sound alert on decayed"],
        5 => ["Sound alert (step right after)"],
        6 => ["No sound alert (not own)"],
        7 => ["No sound alert (fire-once)"],
        8 => ["No styling (spectator)", "No sound alert (spectator)"],
        9 => ["No time added", "No styling (spectator)", "No sound alert (spectator)"]
    ];

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
        "First n moves are added correctly considering situation is always starting"
    ];

    private function _act_FillGame() 
    {
        var situation:Situation = Situation.starting();
        var turnColor:PieceColor = situation.turnColor;
        for (plyInfo in situation.randomContinuation(25))
        {
            sidebox.handleGameBoardEvent(ContinuationMove(plyInfo.ply, plyInfo.plyStr, turnColor));
            turnColor = opposite(turnColor);
        }
    }

    private var _checks_FillGame:Array<String> = [
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
        "click 'offer draw' => DrawAccepted",
        "click 'offer draw' => DrawDeclined",
        "click 'offer takeback' => TakebackAccepted",
        "click 'offer takeback' => TakebackDeclined",
        "DrawOffered => TakebackOffered"
    ];

    private function _act_GameEnded() 
    {
        sidebox.handleNetEvent(GameEnded('w', 'mat'));
    }

    private var _checks_GameEnded:Array<String> = [
        "Timers are stopped",
        "0/1/3/4/6/7/9/10: action button set is changed"
    ];

    private function _act_RollbackThree() 
    {
        sidebox.handleNetEvent(Rollback(3));
    }

    private var _checks_RollbackThree:Array<String> = [
        "History cut correctly",
        "ContinuationMove processed correctly after a rollback",
        "Current timer stops, Another timer starts running, WAIT/MOVE styles are reverted",
        "Draw disabled if rolled too far",
        "Takeback disabled if rolled too far",
        "Draw reenabled after rolled too far + moved",
        "Takeback reenabled if rolled too far + moved"
    ];

    private function _act_correctTime() 
    {
        var ts = Date.now().getTime() - 200;
        sidebox.handleNetEvent(TimeCorrection(124, 9, ts, 'b'));
    }

    private var _checks_correctTime:Array<String> = [
        "Time set to 2:04 white / 0:08.800 black",
        "4/10: black timer critical + no sound",
        "1/7: black timer critical + sound",
        "others: both timers not critical + no sound"
    ];

    public function new()
    {
        super();
    }
}