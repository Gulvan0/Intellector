package gfx;

import gfx.live.models.AnalysisBoardModel;
import gfx.live.models.MatchVersusPlayerModel;
import gfx.live.models.MatchVersusBotModel;
import gfx.live.models.SpectationModel;
import gfx.profile.data.StudyData;
import net.shared.dataobj.ChallengeData;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;
import net.shared.variation.Variation;
import net.shared.variation.VariationPath;
import struct.ChallengeParams;
import net.shared.PieceColor;
import utils.TimeControl;

enum ScreenType
{
    MainMenu;
    Analysis(model:AnalysisBoardModel);
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    MatchVersusPlayer(model:MatchVersusPlayerModel);
    MatchVersusBot(model:MatchVersusBotModel);
    SpectatedMatch(model:SpectationModel);
    PlayerProfile(ownerLogin:String, data:ProfileData);
    ChallengeJoining(data:ChallengeData);
}