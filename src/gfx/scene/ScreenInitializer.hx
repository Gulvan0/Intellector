package gfx.scene;

import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.dataobj.GameModelData;
import net.shared.dataobj.ChallengeData;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;
import net.shared.variation.Variation;
import net.shared.variation.VariationPath;
import net.shared.dataobj.ChallengeParams;
import net.shared.PieceColor;
import net.shared.TimeControl;

enum ScreenInitializer
{
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    MainMenu;
    GameFromModelData(data:GameModelData, ?orientationPariticipantLogin:String);
    StartedGameVersusBot(params:ChallengeParams);
    NewAnalysisBoard;
    Study(info:StudyInfo);
    AnalysisForLine(startingSituation:Situation, plys:Array<RawPly>, viewedMovePointer:Int);
    PlayerProfile(ownerLogin:String, data:ProfileData);
    ChallengeJoining(data:ChallengeData);
}