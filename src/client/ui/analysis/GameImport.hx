package client.ui.analysis;

import client.datatypes.game.LiveGameInfo;
import client.datatypes.game.LiveGameState;
import client.datatypes.variations.PlyTree;
import client.datatypes.variations.PlyTreeNode;
import client.utils.TimedLoad;
import http.HttpError;
import net.models.game.GamePublic;
import net.models.game.mappers.LiveGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;

/** A game's plies as one line of a ply tree, with the node to show **/
typedef ImportedGame =
{
    tree:PlyTree,
    selected:PlyTreeNode
}

/** Fetches a game for the analysis board, trying again after a failure other than the game not existing **/
class GameImport
{
    private static inline final ATTEMPT_LIMIT:Int = 3;

    private final load:TimedLoad = new TimedLoad();
    private var attemptsMade:Int = 0;

    public function new() {}

    /**
        `onFailed` gets the last error, null for a timeout. `plyCount` selects the node after that
        many plies; out of range, the line's last node is selected.
    **/
    public function start(gameId:Int, plyCount:Null<Int>, onLoaded:ImportedGame->Void, onFailed:Null<HttpError>->Void):Void
    {
        attemptsMade++;
        load.start(
            (onResponse, onError) -> Rest.client().execute(RestOperationRegistry.GET_GAME, onResponse, onError, ["game_id" => Std.string(gameId)]),
            (game:GamePublic) -> onLoaded(importedGame(game, plyCount)),
            error -> {
                if (attemptsMade < ATTEMPT_LIMIT && (error == null || error.httpStatus != 404))
                    start(gameId, plyCount, onLoaded, onFailed);
                else
                    onFailed(error);
            }
        );
    }

    public function cancel():Void
    {
        load.cancel();
    }

    private static function importedGame(game:GamePublic, plyCount:Null<Int>):ImportedGame
    {
        var info:LiveGameInfo = LiveGameMapper.infoToDatatype(game);
        var state:LiveGameState = new LiveGameState(info, LiveGameMapper.eventsToDatatype(game.events), null, null);
        var tree:PlyTree = new PlyTree(info.startingPosition);
        var node:PlyTreeNode = tree.root;
        var line:Array<PlyTreeNode> = [node];
        for (i in 0...state.history.plyCount())
        {
            node = tree.play(node, state.history.plyAt(i));
            line.push(node);
        }

        var selectedIndex:Int = plyCount != null && plyCount >= 0 && plyCount < line.length ? plyCount : line.length - 1;
        return {tree: tree, selected: line[selectedIndex]};
    }
}
