package gfx;

import struct.PieceColor;
import utils.TimeControl;
import struct.ActualizationData;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, exploredStudyID:Null<Int>, exploredStudyName:String);
    LanguageSelectIntro(languageReadyCallback:Void->Void);
    StartedPlayableGame(gameID:Int, whiteLogin:String, blackLogin:String, timeControl:TimeControl, playerColor:PieceColor);
    ReconnectedPlayableGame(gameID:Int, actualizationData:ActualizationData);
    SpectatedGame(gameID:Int, watchedColor:PieceColor, actualizationData:ActualizationData);
    RevisitedGame(gameID:Int, watchedColor:PieceColor, actualizationData:ActualizationData);
    PlayerProfile(ownerLogin:String);
    LoginRegister;
    ChallengeHosting(timeControl:TimeControl, color:Null<PieceColor>);
    ChallengeJoining(challengeOwner:String, timeControl:TimeControl, color:Null<PieceColor>);
}