package engine.hxconda.search;

import engine.hxconda.board.Move;

/**
    What a search learns and a later search of the same game can reuse: the transposition table, the history statistics
    and the killer moves. Valid only for searches evaluating the same way, see `Evaluation.useStyle`.
**/
class SearchMemory
{
    public final table:TranspositionTable = new TranspositionTable();
    public final history:SearchHistory = new SearchHistory();
    /** Per ply from the root, the two latest distinct quiet moves that caused a cutoff there, the latest first **/
    public final killers:Array<Move> = [for (_ in 0...2 * SearchTuning.KILLER_PLY_COUNT) Move.NONE];

    /**
        Prepares the memory for a search of the same game, rooted `SearchTuning.PLIES_BETWEEN_SEARCHES` plies after the previous one:
        the table's entries become stale, the history decays and the killers move to the plies they now belong to.
    **/
    public function startNextSearch():Void
    {
        table.startNextSearch();
        history.decay(SearchTuning.HISTORY_DECAY_DIVISOR);

        var shift:Int = 2 * SearchTuning.PLIES_BETWEEN_SEARCHES;
        for (i in 0...killers.length)
            killers[i] = i + shift < killers.length ? killers[i + shift] : Move.NONE;
    }

    public function new() {}
}
