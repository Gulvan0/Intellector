package gfx;

import struct.PieceColor;
import utils.TimeControl;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, exploredStudyID:Null<Int>);
    LanguageSelectIntro;
    StartedPlayableGame(gameID:Int, whiteLogin:String, blackLogin:String, timeControl:TimeControl, playerColor:PieceColor);
    ReconnectedPlayableGame(gameID:Int, actualizationData:ActualizationData);
    SpectatedGame(gameID:Int, watchedColor:PieceColor, actualizationData:ActualizationData);
    RevisitedGame(gameID:Int, watchedColor:PieceColor, log:String);
    PlayerProfile(ownerLogin:String);
    LoginRegister;
    ChallengeHosting(timeControl:TimeControl, color:Null<PieceColor>);
    ChallengeJoining(challengeOwner:String);
}