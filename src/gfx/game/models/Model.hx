package gfx.game.models;

enum Model
{
    MatchVersusPlayer(model:MatchVersusPlayerModel);
    MatchVersusBot(model:MatchVersusBotModel);
    Spectation(model:SpectationModel);
    AnalysisBoard(model:AnalysisBoardModel);
}