import client.datatypes.ChallengeInboxTest;
import client.datatypes.ChallengeQueueTest;
import client.ui.common.board.BoardGeometryTest;
import client.ui.common.board.BoardInputOptionsTest;
import client.ui.common.board.BoardProjectionTest;
import client.ui.common.board.HexTintsTest;
import client.ui.common.board.PremoveQueueTest;
import client.ui.common.board.PremovesTest;
import client.ui.common.board.annotations.BoardAnnotationsTest;
import client.ui.common.board.tools.AnalysisMovePolicyTest;
import client.ui.common.board.tools.AnnotationToolTest;
import client.ui.common.board.tools.EditorMovePolicyTest;
import client.ui.common.board.tools.HexEditToolTest;
import client.ui.common.board.tools.InertMovePolicyTest;
import client.ui.common.board.tools.LiveGameMovePolicyTest;
import client.ui.common.board.tools.MoveCompletionTest;
import client.ui.common.board.tools.PieceMoveToolTest;
import client.ui.common.notifications.challenges.ChallengeStackLayoutTest;
import utest.UTest;

class TestMain
{
    public static function main():Void
    {
        UTest.run([
            new ChallengeQueueTest(),
            new ChallengeInboxTest(),
            new ChallengeStackLayoutTest(),
            new BoardGeometryTest(),
            new BoardProjectionTest(),
            new BoardInputOptionsTest(),
            new PremoveQueueTest(),
            new MoveCompletionTest(),
            new AnalysisMovePolicyTest(),
            new EditorMovePolicyTest(),
            new InertMovePolicyTest(),
            new LiveGameMovePolicyTest(),
            new HexTintsTest(),
            new BoardAnnotationsTest(),
            new PremovesTest(),
            new AnnotationToolTest(),
            new HexEditToolTest(),
            new PieceMoveToolTest()
        ]);
    }
}
