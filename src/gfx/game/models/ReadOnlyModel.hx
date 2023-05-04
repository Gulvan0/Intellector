package gfx.game.models;

import gfx.game.interfaces.IReadOnlyAnalysisBoardModel;
import gfx.game.interfaces.IReadOnlySpectationModel;
import gfx.game.interfaces.IReadOnlyMatchVersusBotModel;
import gfx.game.interfaces.IReadOnlyMatchVersusPlayerModel;

enum ReadOnlyModel
{
    MatchVersusPlayer(model:IReadOnlyMatchVersusPlayerModel);
    MatchVersusBot(model:IReadOnlyMatchVersusBotModel);
    Spectation(model:IReadOnlySpectationModel);
    AnalysisBoard(model:IReadOnlyAnalysisBoardModel);
}