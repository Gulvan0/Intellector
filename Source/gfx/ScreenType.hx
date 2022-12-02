package gfx;

import net.shared.dataobj.ChallengeData;
import net.shared.dataobj.StudyInfo;
import net.shared.dataobj.ProfileData;
import struct.ChallengeParams;
import struct.Variant.VariantPath;
import gfx.game.LiveGameConstructor;
import net.shared.PieceColor;
import utils.TimeControl;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, selectedMainlineMove:Null<Int>, exploredStudyID:Null<Int>, exploredStudyInfo:Null<StudyInfo>);
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    LiveGame(gameID:Int, constructor:LiveGameConstructor);
    PlayerProfile(ownerLogin:String, data:ProfileData);
    ChallengeJoining(data:ChallengeData);
}