package gfx;

import struct.ChallengeParams;
import struct.Variant.VariantPath;
import gfx.game.LiveGameConstructor;
import struct.PieceColor;
import utils.TimeControl;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, selectedMainlineMove:Null<Int>, exploredStudyID:Null<Int>, exploredStudyName:String);
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    LiveGame(gameID:Int, constructor:LiveGameConstructor);
    PlayerProfile(ownerLogin:String);
    ChallengeJoining(id:Int, params:ChallengeParams);
}