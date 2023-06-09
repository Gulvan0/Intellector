package gfx.scene;

import net.shared.utils.PlayerRef;
import net.shared.board.RawPly;
import net.shared.board.Situation;
import net.shared.dataobj.GameModelData;
import net.shared.dataobj.ChallengeData;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;

enum ScreenInitializer
{
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    MainMenu;
    GameFromModelData(data:GameModelData, ?orientationPariticipant:PlayerRef);
    NewAnalysisBoard;
    Study(info:StudyInfo);
    AnalysisForLine(startingSituation:Situation, plys:Array<RawPly>, viewedMovePointer:Int);
    PlayerProfile(ownerLogin:String, data:ProfileData);
    ChallengeJoining(data:ChallengeData);
}