import client.logic.challenge.creation.CalleeParsingTest;
import client.logic.challenge.creation.ChallengeDraftRulesTest;
import client.datatypes.challenge.ChallengeInboxTest;
import client.datatypes.challenge.ChallengeQueueTest;
import client.logic.challenge.creation.ChallengeTimeControlRulesTest;
import client.datatypes.game.GameClockTest;
import client.datatypes.game.LiveGameStateTest;
import client.datatypes.variations.PlyTreeCursorTest;
import client.datatypes.variations.PlyTreePathTest;
import client.datatypes.variations.PlyTreeTest;
import client.datatypes.variations.PositionDraftTest;
import client.logic.variations.PlainTextBlocksTest;
import client.logic.variations.TreeGridTest;
import client.logic.game.OngoingGameOrderingTest;
import client.formatters.ClockFormattersTest;
import client.formatters.PluralsTest;
import client.formatters.VariationFormattersTest;
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
import net.models.challenge.mappers.ChallengeParamsMapperTest;
import net.models.study.mappers.StudyPlyTreeMapperTest;
import utest.UTest;

class TestMain
{
    public static function main():Void
    {
        UTest.run([
            new ChallengeQueueTest(),
            new ChallengeInboxTest(),
            new CalleeParsingTest(),
            new ChallengeDraftRulesTest(),
            new ChallengeTimeControlRulesTest(),
            new ChallengeStackLayoutTest(),
            new GameClockTest(),
            new LiveGameStateTest(),
            new OngoingGameOrderingTest(),
            new ClockFormattersTest(),
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
            new PieceMoveToolTest(),
            new ChallengeParamsMapperTest(),
            new PlyTreeTest(),
            new PlyTreePathTest(),
            new PlyTreeCursorTest(),
            new PositionDraftTest(),
            new TreeGridTest(),
            new PlainTextBlocksTest(),
            new PluralsTest(),
            new VariationFormattersTest(),
            new StudyPlyTreeMapperTest()
        ]);
    }
}
