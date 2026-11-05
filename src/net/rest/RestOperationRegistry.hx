package net.rest;

import easyrest.NoPayload;
import easyrest.NoResponse;
import jsonmodel.UnserializableArray;
import haxe.http.HttpMethod;
import easyrest.GetOperation;
import easyrest.GenericRestOperation;
import net.models.auth.AuthCredentials;
import net.models.auth.GuestTokenResponse;
import net.models.auth.TokenResponse;
import net.models.auth.WhoamiResponse;
import net.models.challenge.ChallengeCreateDirect;
import net.models.challenge.ChallengeCreateOpen;
import net.models.challenge.ChallengeCreateResponse;
import net.models.challenge.ChallengePublic;
import net.models.other.ClientErrorReport;
import net.models.game.external.ExternalGameAppendPlyPayload;
import net.models.game.external.ExternalGameCreatePayload;
import net.models.game.external.ExternalGameEndPayload;
import net.models.game.external.ExternalGameHeartbeatPayload;
import net.models.game.external.ExternalGameRollbackPayload;
import net.models.game.GameAddTimePayload;
import net.models.game.GameSendChatMessagePayload;
import net.models.game.GameSearchPayload;
import net.models.game.GameSearchResult;
import net.models.game.internal.InternalGameAppendPlyPayload;
import net.models.game.internal.InternalGamePerformOfferActionPayload;
import net.models.game.internal.InternalGameResignPayload;
import net.models.game.external.ExternalGameAppendPlyResponse;
import net.models.game.GamePublic;
import net.models.game.GameSummaryPublic;
import net.models.game.internal.InternalGameAppendPlyResponse;
import net.models.player.PlayerUpdate;
import net.models.player.PlayerPublic;
import net.models.player.PlayerGameStats;
import net.models.player.PlayerConnections;
import net.models.player.PlayerRelation;
import net.models.player.PlayerSearchResult;
import net.models.player.EloHistoryEntry;
import net.models.study.ListStudiesPayload;
import net.models.study.ListStudiesResult;
import net.models.study.StudyCreate;
import net.models.study.StudyUpdate;
import net.models.study.StudyPublic;
import net.models.study.StudySummaryPublic;

class RestOperationRegistry
{
    public static final REPORT_CLIENT_ERROR:GenericRestOperation<ClientErrorReport, NoResponse> = new GenericRestOperation<ClientErrorReport, NoResponse>("/client_error", Post);

    public static final AUTH_AS_GUEST:GetOperation<GuestTokenResponse> = new GetOperation<GuestTokenResponse>("/auth/guest");
    public static final WHOAMI:GetOperation<WhoamiResponse> = new GetOperation<WhoamiResponse>("/auth/whoami");
    public static final SIGN_IN:GenericRestOperation<AuthCredentials, TokenResponse> = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/signin", Post);
    public static final REGISTER:GenericRestOperation<AuthCredentials, TokenResponse> = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/register", Post);

    public static final CREATE_OPEN_CHALLENGE:GenericRestOperation<ChallengeCreateOpen, ChallengeCreateResponse> = new GenericRestOperation<ChallengeCreateOpen, ChallengeCreateResponse>("/challenge/create/open", Post);
    public static final CREATE_DIRECT_CHALLENGE:GenericRestOperation<ChallengeCreateDirect, ChallengeCreateResponse> = new GenericRestOperation<ChallengeCreateDirect, ChallengeCreateResponse>("/challenge/create/direct", Post);
    public static final GET_PUBLIC_CHALLENGES:GetOperation<UnserializableArray<ChallengePublic>> = new GetOperation<UnserializableArray<ChallengePublic>>("/challenge/public");
    public static final GET_MY_DIRECT_CHALLENGES:GetOperation<UnserializableArray<ChallengePublic>> = new GetOperation<UnserializableArray<ChallengePublic>>("/challenge/my_direct");
    public static final GET_CHALLENGE:GetOperation<ChallengePublic> = new GetOperation<ChallengePublic>("/challenge/{challenge_id}");
    public static final CANCEL_CHALLENGE:GenericRestOperation<NoPayload, NoResponse> = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}", Delete);
    public static final ACCEPT_CHALLENGE:GenericRestOperation<NoPayload, GameSummaryPublic> = new GenericRestOperation<NoPayload, GameSummaryPublic>("/challenge/{challenge_id}/accept", Post);
    public static final DECLINE_CHALLENGE:GenericRestOperation<NoPayload, NoResponse> = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}/decline", Post);

    public static final SEARCH_GAMES:GenericRestOperation<GameSearchPayload, GameSearchResult> = new GenericRestOperation<GameSearchPayload, GameSearchResult>("/game/search", Post);
    public static final GET_GAME:GetOperation<GamePublic> = new GetOperation<GamePublic>("/game/{game_id}");
    public static final CHECK_TIMEOUT:GetOperation<NoResponse> = new GetOperation<NoResponse>("/game/{game_id}/check_timeout");
    public static final GAME_SEND_CHAT_MESSAGE:GenericRestOperation<GameSendChatMessagePayload, NoResponse> = new GenericRestOperation<GameSendChatMessagePayload, NoResponse>("/game/chat/send_message", Post);
    public static final GAME_ADD_TIME:GenericRestOperation<GameAddTimePayload, NoResponse> = new GenericRestOperation<GameAddTimePayload, NoResponse>("/game/add_time", Post);
    public static final CREATE_EXTERNAL_GAME:GenericRestOperation<ExternalGameCreatePayload, GameSummaryPublic> = new GenericRestOperation<ExternalGameCreatePayload, GameSummaryPublic>("/game/external/create", Post);
    public static final APPEND_PLY_TO_EXTERNAL_GAME:GenericRestOperation<ExternalGameAppendPlyPayload, ExternalGameAppendPlyResponse> = new GenericRestOperation<ExternalGameAppendPlyPayload, ExternalGameAppendPlyResponse>("/game/external/append_ply", Post);
    public static final END_EXTERNAL_GAME:GenericRestOperation<ExternalGameEndPayload, NoResponse> = new GenericRestOperation<ExternalGameEndPayload, NoResponse>("/game/external/end", Post);
    public static final HEARTBEAT_EXTERNAL_GAME:GenericRestOperation<ExternalGameHeartbeatPayload, NoResponse> = new GenericRestOperation<ExternalGameHeartbeatPayload, NoResponse>("/game/external/heartbeat", Post);
    public static final APPEND_ROLLBACK_TO_EXTERNAL_GAME:GenericRestOperation<ExternalGameRollbackPayload, NoResponse> = new GenericRestOperation<ExternalGameRollbackPayload, NoResponse>("/game/external/rollback", Post);
    public static final APPEND_PLY_TO_INTERNAL_GAME:GenericRestOperation<InternalGameAppendPlyPayload, InternalGameAppendPlyResponse> = new GenericRestOperation<InternalGameAppendPlyPayload, InternalGameAppendPlyResponse>("/game/internal/append_ply", Post);
    public static final PERFORM_OFFER_ACTION_IN_INTERNAL_GAME:GenericRestOperation<InternalGamePerformOfferActionPayload, NoResponse> = new GenericRestOperation<InternalGamePerformOfferActionPayload, NoResponse>("/game/internal/perform_offer_action", Post);
    public static final RESIGN_INTERNAL_GAME:GenericRestOperation<InternalGameResignPayload, NoResponse> = new GenericRestOperation<InternalGameResignPayload, NoResponse>("/game/internal/resign", Post);

    public static final SEARCH_PLAYERS:GetOperation<PlayerSearchResult> = new GetOperation<PlayerSearchResult>("/player/search");
    public static final GET_PLAYER_CONNECTIONS:GetOperation<PlayerConnections> = new GetOperation<PlayerConnections>("/player/{login}/connections");
    public static final GET_PLAYER_RELATION:GetOperation<PlayerRelation> = new GetOperation<PlayerRelation>("/player/{login}/relation");
    public static final GET_ELO_HISTORY:GetOperation<UnserializableArray<EloHistoryEntry>> = new GetOperation<UnserializableArray<EloHistoryEntry>>("/player/{login}/elo_history");
    public static final GET_PLAYER:GetOperation<PlayerPublic> = new GetOperation<PlayerPublic>("/player/{login}");
    public static final UPDATE_PLAYER:GenericRestOperation<PlayerUpdate, NoResponse> = new GenericRestOperation<PlayerUpdate, NoResponse>("/player/{login}", Patch);
    public static final FOLLOW_PLAYER:GenericRestOperation<NoPayload, NoResponse> = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/follow", Post);
    public static final UNFOLLOW_PLAYER:GenericRestOperation<NoPayload, NoResponse> = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/unfollow", Post);
    public static final GET_GAME_STATS:GetOperation<PlayerGameStats> = new GetOperation<PlayerGameStats>("/player/{login}/game_stats");

    public static final CREATE_STUDY:GenericRestOperation<StudyCreate, StudySummaryPublic> = new GenericRestOperation<StudyCreate, StudySummaryPublic>("/study/create", Post);
    public static final LIST_STUDIES:GenericRestOperation<ListStudiesPayload, ListStudiesResult> = new GenericRestOperation<ListStudiesPayload, ListStudiesResult>("/study/list", Post);
    public static final GET_STUDY:GetOperation<StudyPublic> = new GetOperation<StudyPublic>("/study/{study_id}");
    public static final UPDATE_STUDY:GenericRestOperation<StudyUpdate, StudyPublic> = new GenericRestOperation<StudyUpdate, StudyPublic>("/study/{study_id}", Patch);
    public static final DELETE_STUDY:GenericRestOperation<NoPayload, NoResponse> = new GenericRestOperation<NoPayload, NoResponse>("/study/{study_id}", Delete);
}
