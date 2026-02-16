package net.rest;

import lib.rest.NoResponse;
import lib.json.UnserializableArray;
import haxe.http.HttpMethod;
import lib.rest.GetOperaton;
import lib.rest.GenericRestOperation;
import net.rest.models.common.UserRefWithNickname;
import net.rest.models.auth.request.AuthCredentials;
import net.rest.models.auth.response.GuestTokenResponse;
import net.rest.models.auth.response.TokenResponse;
import net.rest.models.challenge.request.ChallengeCreateDirect;
import net.rest.models.challenge.request.ChallengeCreateOpen;
import net.rest.models.challenge.response.ChallengeCreateResponse;
import net.rest.models.challenge.response.ChallengePublic;
import net.rest.models.game.request.ExternalGameAppendPlyPayload;
import net.rest.models.game.request.ExternalGameCreatePayload;
import net.rest.models.game.request.ExternalGameEndPayload;
import net.rest.models.game.request.ExternalGameRollbackPayload;
import net.rest.models.game.request.GameAddTimePayload;
import net.rest.models.game.request.GameSendChatMessagePayload;
import net.rest.models.game.request.InternalGameAppendPlyPayload;
import net.rest.models.game.request.InternalGamePerformOfferActionPayload;
import net.rest.models.game.response.ExternalGameAppendPlyResponse;
import net.rest.models.game.response.GamePublic;
import net.rest.models.game.response.InternalGameAppendPlyResponse;
import net.rest.models.other.request.CompatibilityCheckPayload;
import net.rest.models.other.response.CompatibilityResponse;
import net.rest.models.player.request.PlayerUpdate;
import net.rest.models.player.response.PlayerPublic;
import net.rest.models.study.request.ListStudiesPayload;
import net.rest.models.study.request.StudyCreate;
import net.rest.models.study.request.StudyUpdate;
import net.rest.models.study.response.StudyPublic;

class RestOperation
{
    public static final AUTH_AS_GUEST = new GetOperaton<GuestTokenResponse>("/auth/guest");
    public static final SIGN_IN = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/signin", Post);
    public static final REGISTER = new GenericRestOperation<AuthCredentials, TokenResponse>("/auth/register", Post);

    public static final CREATE_OPEN_CHALLENGE = new GenericRestOperation<ChallengeCreateOpen, ChallengeCreateResponse>("/challenge/create/open", Post);
    public static final CREATE_DIRECT_CHALLENGE = new GenericRestOperation<ChallengeCreateDirect, ChallengeCreateResponse>("/challenge/create/direct", Post);
    public static final GET_PUBLIC_CHALLENGES = new GetOperaton<UnserializableArray<ChallengePublic>>("/challenge/public");
    public static final GET_MY_DIRECT_CHALLENGES = new GetOperaton<UnserializableArray<ChallengePublic>>("/challenge/my_direct");
    public static final GET_CHALLENGE = new GetOperaton<ChallengePublic>("/challenge/{challenge_id}");
    public static final CANCEL_CHALLENGE = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}", Delete);
    public static final ACCEPT_CHALLENGE = new GenericRestOperation<NoPayload, GamePublic>("/challenge/{challenge_id}/accept", Post);
    public static final DECLINE_CHALLENGE = new GenericRestOperation<NoPayload, NoResponse>("/challenge/{challenge_id}/decline", Post);

    public static final GET_CURRENT_GAMES = new GenericRestOperation<GameFilter, UnserializableArray<GamePublic>>("/game/current", Post);
    public static final GET_RECENT_GAMES = new GenericRestOperation<GameFilter, UnserializableArray<GamePublic>>("/game/recent", Post);
    public static final GET_GAME = new GetOperaton<GamePublic>("/game/{game_id}");
    public static final CHECK_TIMEOUT = new GetOperaton<NoPayload>("/game/{game_id}/check_timeout");
    public static final GAME_SEND_CHAT_MESSAGE = new GenericRestOperation<GameSendChatMessagePayload, NoResponse>("/game/chat/send_message", Post);
    public static final GAME_ADD_TIME = new GenericRestOperation<GameAddTimePayload, NoResponse>("/game/add_time", Post);
    public static final CREATE_EXTERNAL_GAME = new GenericRestOperation<ExternalGameCreatePayload, GamePublic>("/game/external/create", Post);
    public static final APPEND_PLY_TO_EXTERNAL_GAME = new GenericRestOperation<ExternalGameAppendPlyPayload, ExternalGameAppendPlyResponse>("/game/external/append_ply", Post);
    public static final END_EXTERNAL_GAME = new GenericRestOperation<ExternalGameEndPayload, NoResponse>("/game/external/end", Post);
    public static final APPEND_ROLLBACK_TO_EXTERNAL_GAME = new GenericRestOperation<ExternalGameRollbackPayload, NoResponse>("/game/external/rollback", Post);
    public static final APPEND_PLY_TO_INTERNAL_GAME = new GenericRestOperation<InternalGameAppendPlyPayload, InternalGameAppendPlyResponse>("/game/internal/append_ply", Post);
    public static final PERFORM_OFFER_ACTION_IN_INTERNAL_GAME = new GenericRestOperation<InternalGamePerformOfferActionPayload, NoResponse>("/game/internal/perform_offer_action", Post);

    public static final CHECK_COMPATIBILITY = new GenericRestOperation<CompatibilityCheckPayload, CompatibilityResponse>("/check_compatibility", Post);

    public static final GET_PLAYER_FOLLOWERS = new GetOperaton<UnserializableArray<UserRefWithNickname>>("/player/{login}/followers");
    public static final GET_FOLLOWED_PLAYERS = new GetOperaton<UnserializableArray<UserRefWithNickname>>("/player/{login}/followed");
    public static final GET_PLAYER = new GetOperaton<PlayerPublic>("/player/{login}");
    public static final UPDATE_PLAYER = new GenericRestOperation<PlayerUpdate, NoResponse>("/player/{login}", Patch);
    public static final FOLLOW_PLAYER = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/follow", Post);
    public static final UNFOLLOW_PLAYER = new GenericRestOperation<NoPayload, NoResponse>("/player/{login}/unfollow", Post);

    public static final CREATE_STUDY = new GenericRestOperation<StudyCreate, StudyPublic>("/study/create", Post);
    public static final LIST_STUDIES = new GenericRestOperation<ListStudiesPayload, UnserializableArray<StudyPublic>>("/study/list", Post);
    public static final GET_STUDY = new GetOperaton<StudyPublic>("/study/{study_id}");
    public static final UPDATE_STUDY = new GenericRestOperation<StudyUpdate, StudyPublic>("/study/{study_id}", Patch);
    public static final DELETE_STUDY = new GenericRestOperation<NoPayload, StudyPublic>("/study/{study_id}", Delete);
}
