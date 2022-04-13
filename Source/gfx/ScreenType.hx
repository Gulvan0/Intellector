package gfx;

enum ScreenType
{
    MainMenu;
    Analysis(initialVariantStr:Null<String>, exploredStudyID:Null<Int>);
    LanguageSelectIntro;
    PlayableGame(gameID:Int, whiteLogin:String, blackLogin:String, timeControl:TimeControl, playerColor:PieceColor, pastLog:Null<String>);
    SpectatedGame(gameID:Int, whiteLogin:String, blackLogin:String, watchedColor:PieceColor, timeControl:TimeControl, pastLog:String);
    RevisitedGame(gameID:Int, whiteLogin:String, blackLogin:String, watchedColor:PieceColor, timeControl:TimeControl, log:String);
    PlayerProfile(ownerLogin:String);
    LoginRegister;
}