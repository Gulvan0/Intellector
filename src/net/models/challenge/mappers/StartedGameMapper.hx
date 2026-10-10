package net.models.challenge.mappers;

import client.datatypes.StartedGame;
import net.models.common.UserRefWithNickname;
import net.models.game.GameSummaryPublic;

class StartedGameMapper
{
    /** The game the caller of `dto` plays, or null while it isn't accepted **/
    public static function resultingGameToDatatype(dto:ChallengePublic):Null<StartedGame>
    {
        var game:Null<GameSummaryPublic> = dto.resulting_game;
        if (game == null)
            return null;

        var opponent:UserRefWithNickname = game.white_player.user_ref == dto.caller.user_ref ? game.black_player : game.white_player;
        return new StartedGame(game.id, opponent.nickname);
    }
}
