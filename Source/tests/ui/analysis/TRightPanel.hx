package tests.ui.analysis;

import tests.ui.TestedComponent.ComponentGraphics;

class TRightPanel extends TestedComponent //TODO: Add more tests
{
    //TODO: Implement

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

	function getComponent():ComponentGraphics {
		throw new haxe.exceptions.NotImplementedException();
	}

	function rebuildComponent() {}
}