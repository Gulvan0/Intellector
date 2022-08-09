package gfx;

import gfx.game.LiveGameConstructor;
import struct.PieceColor;
import utils.TimeControl;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, exploredStudyID:Null<Int>, exploredStudyName:String);
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    LiveGame(gameID:Int, constructor:LiveGameConstructor);
    PlayerProfile(ownerLogin:String);
    ChallengeJoining(challengeOwner:String, timeControl:TimeControl, color:Null<PieceColor>);
}