package net.models.game.mappers;

import client.datatypes.game.GameChatMessage;
import client.datatypes.game.GameEnding;
import client.datatypes.game.GameParticipant;
import client.datatypes.game.LiveGameEvent;
import client.datatypes.game.LiveGameInfo;
import client.datatypes.game.Outcome;
import client.datatypes.game.PlayerRating;
import intellectorboard.mappers.Sip;
import intellectorboard.position.Position;
import intellectorboard.primitives.ply.RawPly;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.HexCoordsMapper;
import net.models.common.mappers.PieceColorMapper;
import net.models.common.mappers.PieceKindMapper;
import net.models.common.mappers.TimeControlMapper;
import net.models.game.internal.InternalGameAppendPlyPayload;
import net.models.game.internal.InternalGamePerformOfferActionPayload;

class LiveGameMapper
{
    public static function infoToDatatype(dto:GamePublic):LiveGameInfo
    {
        var startingSip:Null<String> = dto.custom_starting_sip;
        var startingPosition:Position = startingSip != null ? new Sip(startingSip).toPosition() ?? Position.defaultStarting() : Position.defaultStarting();
        return new LiveGameInfo(
            dto.id,
            participantToDatatype(dto.white_player, dto.white_rating),
            participantToDatatype(dto.black_player, dto.black_rating),
            TimeControlMapper.dtoToDatatype(dto.fischer_time_control),
            dto.rated,
            dto.started_at != null ? dto.started_at.getUnixMs() : null,
            startingPosition,
            startingSip != null,
            dto.external_uploader_ref != null
        );
    }

    public static function eventsToDatatype(dtos:Array<GameEvent>):Array<LiveGameEvent>
    {
        var events:Array<LiveGameEvent> = [];
        for (dto in dtos)
        {
            var event:Null<LiveGameEvent> = eventToDatatype(dto);
            if (event != null)
                events.push(event);
        }
        return events;
    }

    public static function plyToDatatype(dto:PlyBroadcastedData):LiveGameEvent
    {
        var ply:RawPly = RawPly.construct(
            new intellectorboard.primitives.hex.HexCoords(dto.from_i, dto.from_j),
            new intellectorboard.primitives.hex.HexCoords(dto.to_i, dto.to_j),
            dto.morph_into != null ? PieceKindMapper.dtoToDatatype(dto.morph_into) : null
        );
        return LiveGameEvent.Ply(dto.event_index, dto.ply_index, ply, GameClockMapper.dtoToDatatype(dto.time_update));
    }

    public static function chatMessageToDatatype(dto:ChatMessageBroadcastedData):LiveGameEvent
    {
        return LiveGameEvent.ChatMessage(dto.event_index, new GameChatMessage(dto.author.user_ref, dto.author.nickname, dto.text, dto.spectator));
    }

    public static function offerToDatatype(dto:OfferActionBroadcastedData):LiveGameEvent
    {
        return LiveGameEvent.Offer(dto.event_index, offerActionToDatatype(dto.action), offerKindToDatatype(dto.offer_kind), PieceColorMapper.dtoToDatatype(dto.offer_author));
    }

    public static function timeAddedToDatatype(dto:TimeAddedBroadcastedData):LiveGameEvent
    {
        return LiveGameEvent.TimeAdded(dto.event_index, PieceColorMapper.dtoToDatatype(dto.receiver), GameClockMapper.dtoToDatatype(dto.time_update));
    }

    public static function rollbackToDatatype(dto:RollbackBroadcastedData):LiveGameEvent
    {
        return LiveGameEvent.Rollback(dto.event_index, dto.ply_cnt_after, GameClockMapper.dtoToDatatype(dto.time_update));
    }

    public static function outcomeToDatatype(dto:Null<GameOutcomePublic>):Null<GameEnding>
    {
        if (dto == null)
            return null;

        var outcome:Outcome = outcomeKindToDatatype(dto.kind, dto.winner);
        return new GameEnding(outcome, dto.game_ended_at != null ? dto.game_ended_at.getUnixMs() : null, GameClockMapper.dtoToDatatype(dto.time_update), dto.white_elo_delta, dto.black_elo_delta);
    }

    public static function endedToDatatype(dto:GameEndedBroadcastedData):GameEnding
    {
        var outcome:Outcome = outcomeKindToDatatype(dto.kind, dto.winner);
        var whiteDelta:Null<Int> = dto.elo != null ? dto.elo.white.delta : null;
        var blackDelta:Null<Int> = dto.elo != null ? dto.elo.black.delta : null;
        return new GameEnding(outcome, dto.game_ended_at != null ? dto.game_ended_at.getUnixMs() : null, GameClockMapper.dtoToDatatype(dto.time_update), whiteDelta, blackDelta);
    }

    public static function plyToDto(gameId:Int, ply:RawPly):InternalGameAppendPlyPayload
    {
        return {
            game_id: gameId,
            from_i: ply.from.i,
            from_j: ply.from.j,
            to_i: ply.to.i,
            to_j: ply.to.j,
            morph_into: ply.morphInto != null ? PieceKindMapper.datatypeToDto(ply.morphInto) : null
        };
    }

    public static function offerActionToDto(gameId:Int, action:client.datatypes.game.OfferAction, kind:client.datatypes.game.OfferKind):InternalGamePerformOfferActionPayload
    {
        var actionDto:OfferAction = switch action {
            case Create: CREATE;
            case Cancel: CANCEL;
            case Accept: ACCEPT;
            case Decline: DECLINE;
        }
        var kindDto:OfferKind = switch kind {
            case Draw: DRAW;
            case Takeback: TAKEBACK;
        }
        return {game_id: gameId, action_kind: actionDto, offer_kind: kindDto};
    }

    private static function eventToDatatype(dto:GameEvent):Null<LiveGameEvent>
    {
        return switch dto {
            case Ply(_, eventIndex, plyIndex, from, to, morphInto, timeUpdate, isCancelled):
                if (isCancelled)
                    null;
                else
                {
                    var ply:RawPly = RawPly.construct(
                        HexCoordsMapper.dtoToDatatype(from),
                        HexCoordsMapper.dtoToDatatype(to),
                        morphInto != null ? PieceKindMapper.dtoToDatatype(morphInto) : null
                    );
                    LiveGameEvent.Ply(eventIndex, plyIndex, ply, GameClockMapper.dtoToDatatype(timeUpdate));
                }
            case ChatMessage(_, eventIndex, text, spectator, author): LiveGameEvent.ChatMessage(eventIndex, new GameChatMessage(author.user_ref, author.nickname, text, spectator));
            case Offer(_, eventIndex, action, kind, author): LiveGameEvent.Offer(eventIndex, offerActionToDatatype(action), offerKindToDatatype(kind), PieceColorMapper.dtoToDatatype(author));
            case TimeAdded(_, eventIndex, _, receiver, timeUpdate): LiveGameEvent.TimeAdded(eventIndex, PieceColorMapper.dtoToDatatype(receiver), GameClockMapper.dtoToDatatype(timeUpdate));
            case Rollback(_, eventIndex, _, plyCountAfter, _, timeUpdate): LiveGameEvent.Rollback(eventIndex, plyCountAfter, GameClockMapper.dtoToDatatype(timeUpdate));
        }
    }

    private static function participantToDatatype(player:UserRefWithNickname, rating:Null<PlayerRatingPublic>):GameParticipant
    {
        var ratingDatatype:Null<PlayerRating> = rating != null ? new PlayerRating(rating.elo, rating.provisional) : null;
        return new GameParticipant(player.user_ref, player.nickname, ratingDatatype);
    }

    private static function offerActionToDatatype(dto:OfferAction):client.datatypes.game.OfferAction
    {
        return switch dto {
            case CREATE: Create;
            case CANCEL: Cancel;
            case ACCEPT: Accept;
            case DECLINE: Decline;
        }
    }

    private static function offerKindToDatatype(dto:OfferKind):client.datatypes.game.OfferKind
    {
        return switch dto {
            case DRAW: Draw;
            case TAKEBACK: Takeback;
        }
    }

    private static function outcomeKindToDatatype(kind:OutcomeKind, winner:Null<net.models.common.PieceColor>):Outcome
    {
        if (winner != null)
        {
            var decisiveKind:DecisiveOutcomeKind = switch kind {
                case FATUM: Mate;
                case BREAKTHROUGH: Breakthrough;
                case TIMEOUT: Timeout;
                case RESIGN: Resign;
                case CHEATING_ABORT: CheatingAbort;
                default: Abandon;
            }
            return Decisive(decisiveKind, PieceColorMapper.dtoToDatatype(winner));
        }

        var drawishKind:DrawishOutcomeKind = switch kind {
            case DRAW_AGREEMENT: DrawAgreement;
            case REPETITION: Repetition;
            case NO_PROGRESS: NoProgress;
            default: Abort;
        }
        return Drawish(drawishKind);
    }
}
