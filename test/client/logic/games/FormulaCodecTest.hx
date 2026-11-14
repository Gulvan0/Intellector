package client.logic.games;

import client.datatypes.games.ConditionGroup;
import client.datatypes.games.FormulaNode;
import client.logic.games.FormulaCodec.FormulaDecodingException;
import utest.Assert;
import utest.Test;

class FormulaCodecTest extends Test
{
    private static final DOC_EXAMPLE:String = '{"version":1,"root":{"and":[{"property":"started_at","operator":"lt","operands":["2024-06-13"]},{"or":[{"property":"time_control_kind","values":["BLITZ","RAPID"]},{"property":"winner","values":[{"user":"paulnotintellector"},{"guest":23},{"bot":{}}]},{"not":{"property":"elo","parameter":"white","operator":"between","operands":[1500,1800]}}]}]}}';

    private function testDocExampleRoundTrips():Void
    {
        assertRoundTrip(DOC_EXAMPLE);
    }

    private function testEveryValueKindRoundTrips():Void
    {
        assertRoundTrip('{"version":1,"root":{"and":[' + [
            '{"property":"ended_at","operator":"between","operands":["2024-01-01T10:00:00","2024-02-29"]}',
            '{"property":"duration","operator":"unknown","operands":[]}',
            '{"property":"time_left","parameter":{"bot":{"family":"haxaconda_vrezh","level":6}},"operator":"ge","operands":[90000]}',
            '{"property":"elo","parameter":{"user":"abc"},"operator":"eq","operands":[1500]}',
            '{"property":"player","parameter":"any","values":[{"bot":{"family":"anaconda"}},{"bot":{"family":"haxaconda_standard"}}]}',
            '{"property":"rated","values":[true]}',
            '{"property":"outcome","values":["FATUM","CHEATING_ABORT","NO_PROGRESS"]}',
            '{"property":"starting_position","values":["default",{"sip":"2!abc"}]}',
            '{"property":"opening","values":[0,5]}',
            '{"property":"elo_provisional","parameter":"black","values":[false]}',
            '{"property":"winner","values":["ongoing","draw"]}',
            '{"property":"result","values":["white_won","draw"]}'
        ].join(",") + ']}}');
    }

    private function testFragmentRoundTrips():Void
    {
        var root:ConditionGroup = FormulaCodec.decode(DOC_EXAMPLE);
        var fragment:String = FormulaCodec.toFragment(root);
        Assert.isFalse(fragment.indexOf("=") >= 0);
        Assert.isFalse(fragment.indexOf("/") >= 0);
        Assert.equals(DOC_EXAMPLE, FormulaCodec.encode(FormulaCodec.fromFragment(fragment)));
    }

    private function testEmptyFormula():Void
    {
        var json:String = FormulaCodec.encode(ConditionGroup.emptyRoot());
        Assert.equals('{"version":1,"root":{"and":[]}}', json);
        Assert.equals(0, FormulaCodec.decode(json).children.length);
    }

    private function testRequestFormResolvesDateTimes():Void
    {
        var root:ConditionGroup = FormulaCodec.decode('{"version":1,"root":{"and":[{"property":"started_at","operator":"lt","operands":["2024-06-13"]}]}}');
        var json:String = FormulaCodec.encodeForRequest(root, OperandResolverTest.utcPlusTwo);
        Assert.equals('{"version":1,"root":{"and":[{"property":"started_at","operator":"lt","operands":[{"at":"2024-06-12T22:00:00Z","inclusive":false}]}]}}', json);
    }

    private function testRejectsMalformed():Void
    {
        assertRejected("not json");
        assertRejected('{"version":2,"root":{"and":[]}}');
        assertRejected('{"version":1,"root":{"or":[]}}');
        assertRejected('{"version":1,"root":{"and":[]},"extra":1}');
        assertRejected('{"version":1,"root":{"and":[{"and":[]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"not":{"not":{"property":"rated","values":[true]}}}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"nonexistent","values":[1]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"elo","operator":"lt","operands":[1]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"elo","parameter":{"guest":1},"operator":"lt","operands":[1]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"started_at","operator":"le","operands":["2024-01-01"]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"started_at","operator":"lt","operands":["2023-02-29"]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"started_at","operator":"lt","operands":["2024-01-01T24:00:00"]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"move_cnt","operator":"between","operands":[1]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"move_cnt","operator":"lt","operands":[1.5]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"rated","values":[]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"rated","values":[true,false]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"player","parameter":"any","values":[{"user":"Upper"}]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"player","parameter":"any","values":[{"bot":{"family":"anaconda","level":1}}]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"player","parameter":"any","values":[{"bot":{"family":"haxaconda_vrezh","level":9}}]}]}}');
        assertRejected('{"version":1,"root":{"and":[{"property":"opening","values":[100000]}]}}');
    }

    private function testRejectsExceedingCaps():Void
    {
        var leaves:Array<String> = [for (_ in 0...FormulaCaps.MAX_LEAVES + 1) '{"property":"rated","values":[true]}'];
        assertRejected('{"version":1,"root":{"and":[' + leaves.join(",") + ']}}');

        var costly:Array<String> = [for (_ in 0...FormulaCaps.MAX_COSTLY_LEAVES + 1) '{"property":"opening","values":[1]}'];
        assertRejected('{"version":1,"root":{"and":[' + costly.join(",") + ']}}');

        var nested:String = '{"property":"rated","values":[true]}';
        for (i in 0...FormulaCaps.MAX_DEPTH)
            nested = i % 2 == 0 ? '{"or":[$nested]}' : '{"and":[$nested]}';
        assertRejected('{"version":1,"root":{"and":[$nested]}}');

        var padding:String = StringTools.lpad("", "a", FormulaCaps.MAX_FORMULA_LENGTH);
        assertRejected('{"version":1,"root":{"and":[]},"padding":"$padding"}');
    }

    private function testDepthAtCapIsAccepted():Void
    {
        var nested:String = '{"property":"rated","values":[true]}';
        for (i in 0...FormulaCaps.MAX_DEPTH - 1)
            nested = i % 2 == 0 ? '{"or":[$nested]}' : '{"and":[$nested]}';
        var root:ConditionGroup = FormulaCodec.decode('{"version":1,"root":{"and":[$nested]}}');
        Assert.equals(FormulaCaps.MAX_DEPTH, FormulaCaps.count(root).depth);
    }

    private function assertRoundTrip(json:String):Void
    {
        var root:ConditionGroup = FormulaCodec.decode(json);
        Assert.equals(json, FormulaCodec.encode(root));
        Assert.equals(json, FormulaCodec.encode(root.copy()));
    }

    private function assertRejected(json:String):Void
    {
        Assert.raises(() -> FormulaCodec.decode(json), FormulaDecodingException);
    }
}
