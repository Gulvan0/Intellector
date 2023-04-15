package gfx.live.models;

import gfx.live.interfaces.IReadOnlyAnalysisBoardModel;
import gfx.live.interfaces.IReadOnlySpectationModel;
import gfx.live.interfaces.IReadOnlyMatchVersusBotModel;
import gfx.live.interfaces.IReadOnlyMatchVersusPlayerModel;

enum ReadOnlyModel
{
    MatchVersusPlayer(model:IReadOnlyMatchVersusPlayerModel);
    MatchVersusBot(model:IReadOnlyMatchVersusBotModel);
    Spectation(model:IReadOnlySpectationModel);
    AnalysisBoard(model:IReadOnlyAnalysisBoardModel);
}