package net.rest;

import easyrest.NoPayload;
import easyrest.NoResponse;
import jsonmodel.UnserializableArray;
import haxe.http.HttpMethod;
import easyrest.GetOperaton;
import easyrest.GenericRestOperation;
import net.models.auth.AuthCredentials;
import net.models.auth.GuestTokenResponse;
import net.models.auth.TokenResponse;
import net.models.auth.WhoamiResponse;
import net.models.challenge.ChallengeCreateDirect;
import net.models.challenge.ChallengeCreateOpen;
import net.models.challenge.ChallengeCreateResponse;
import net.models.challenge.ChallengePublic;
import net.models.game.external.ExternalGameAppendPlyPayload;
import net.models.game.external.ExternalGameCreatePayload;
import net.models.game.external.ExternalGameEndPayload;
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
import net.models.other.CompatibilityCheckPayload;
import net.models.other.CompatibilityResponse;
import net.models.player.PlayerUpdate;
import net.models.player.PlayerPublic;
import net.models.player.PlayerGameStats;
import net.models.player.PlayerConnections;
import net.models.player.PlayerRelation;
import net.models.player.EloHistoryEntry;
import net.models.study.ListStudiesPayload;
import net.models.study.ListStudiesResult;
import net.models.study.StudyCreate;
import net.models.study.StudyUpdate;
import net.models.study.StudyPublic;
import net.models.study.StudySummaryPublic;

class RestOperationRegistry
{
	public static final AUTH_AS_GUEST = new GetOperaton<GuestTokenResponse>("/auth/guest");
	public static final WHOAMI = new GetOperaton<WhoamiResponse>("/auth/whoami");
	public static final SIGN_IN = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/signin", Post);
	public static final REGISTER = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/register", Post);

	public static final CREATE_OPEN_CHALLENGE = new GenericRestOperation<ChallengeCreateOpen, ChallengeCreateResponse>("/challenge/create/open", Post);
	public static final CREATE_DIRECT_CHALLENGE = new GenericRestOperation<ChallengeCreateDirect, ChallengeCreateResponse>("/challenge/create/direct", Post);
	public static final GET_PUBLIC_CHALLENGES = new GetOperaton<UnserializableArray<ChallengePublic>>("/challenge/public");
	public static final GET_MY_DIRECT_CHALLENGES = new GetOperaton<UnserializableArray<ChallengePublic>>("/challenge/my_direct");
	public static final GET_CHALLENGE = new GetOperaton<ChallengePublic>("/challenge/{challenge_id}");
	public static final CANCEL_CHALLENGE = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}", Delete);
	public static final ACCEPT_CHALLENGE = new GenericRestOperation<NoPayload, GameSummaryPublic>("/challenge/{challenge_id}/accept", Post);
	public static final DECLINE_CHALLENGE = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}/decline", Post);

	public static final SEARCH_GAMES = new GenericRestOperation<GameSearchPayload, GameSearchResult>("/game/search", Post);
	public static final GET_GAME = new GetOperaton<GamePublic>("/game/{game_id}");
	public static final CHECK_TIMEOUT = new GetOperaton<NoResponse>("/game/{game_id}/check_timeout");
	public static final GAME_SEND_CHAT_MESSAGE = new GenericRestOperation<GameSendChatMessagePayload, NoResponse>("/game/chat/send_message", Post);
	public static final GAME_ADD_TIME = new GenericRestOperation<GameAddTimePayload, NoResponse>("/game/add_time", Post);
	public static final CREATE_EXTERNAL_GAME = new GenericRestOperation<ExternalGameCreatePayload, GameSummaryPublic>("/game/external/create", Post);
	public static final APPEND_PLY_TO_EXTERNAL_GAME = new GenericRestOperation<ExternalGameAppendPlyPayload,
		ExternalGameAppendPlyResponse>("/game/external/append_ply", Post);
	public static final END_EXTERNAL_GAME = new GenericRestOperation<ExternalGameEndPayload, NoResponse>("/game/external/end", Post);
	public static final APPEND_ROLLBACK_TO_EXTERNAL_GAME = new GenericRestOperation<ExternalGameRollbackPayload, NoResponse>("/game/external/rollback", Post);
	public static final APPEND_PLY_TO_INTERNAL_GAME = new GenericRestOperation<InternalGameAppendPlyPayload,
		InternalGameAppendPlyResponse>("/game/internal/append_ply", Post);
	public static final PERFORM_OFFER_ACTION_IN_INTERNAL_GAME = new GenericRestOperation<InternalGamePerformOfferActionPayload,
		NoResponse>("/game/internal/perform_offer_action", Post);
	public static final RESIGN_INTERNAL_GAME = new GenericRestOperation<InternalGameResignPayload, NoResponse>("/game/internal/resign", Post);

	public static final CHECK_COMPATIBILITY = new GenericRestOperation<CompatibilityCheckPayload, CompatibilityResponse>("/check_compatibility", Post);

	public static final GET_PLAYER_CONNECTIONS = new GetOperaton<PlayerConnections>("/player/{login}/connections");
	public static final GET_PLAYER_RELATION = new GetOperaton<PlayerRelation>("/player/{login}/relation");
	public static final GET_ELO_HISTORY = new GetOperaton<UnserializableArray<EloHistoryEntry>>("/player/{login}/elo_history");
	public static final GET_PLAYER = new GetOperaton<PlayerPublic>("/player/{login}");
	public static final UPDATE_PLAYER = new GenericRestOperation<PlayerUpdate, NoResponse>("/player/{login}", Patch);
	public static final FOLLOW_PLAYER = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/follow", Post);
	public static final UNFOLLOW_PLAYER = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/unfollow", Post);
	public static final GET_GAME_STATS = new GetOperaton<PlayerGameStats>("/player/{login}/game_stats");

	public static final CREATE_STUDY = new GenericRestOperation<StudyCreate, StudySummaryPublic>("/study/create", Post);
	public static final LIST_STUDIES = new GenericRestOperation<ListStudiesPayload, ListStudiesResult>("/study/list", Post);
	public static final GET_STUDY = new GetOperaton<StudyPublic>("/study/{study_id}");
	public static final UPDATE_STUDY = new GenericRestOperation<StudyUpdate, StudyPublic>("/study/{study_id}", Patch);
	public static final DELETE_STUDY = new GenericRestOperation<NoPayload, NoResponse>("/study/{study_id}", Delete);
}
