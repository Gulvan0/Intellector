package gfx.live.models;

enum Model
{
    MatchVersusPlayer(model:MatchVersusPlayerModel);
    MatchVersusBot(model:MatchVersusBotModel);
    Spectation(model:SpectationModel);
    AnalysisBoard(model:AnalysisBoardModel);
}