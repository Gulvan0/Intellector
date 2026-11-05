package client.ui.common.overlays.challenge;

import client.auth.Identity;
import client.auth.IdentityKeeper;
import client.datatypes.bot.BotSettings;
import client.datatypes.challenge.creation.ChallengeCreationOutcome;
import client.datatypes.challenge.creation.ChallengeDraft;
import client.datatypes.challenge.creation.ChallengeParams;
import client.datatypes.request.FailedAction;
import client.logic.bot.BotRefs;
import client.tabs.GameRedirect;
import client.ui.common.notifications.CalleeOfflineNotice;
import client.ui.common.notifications.RequestFailureNotice;
import http.HttpError;
import intellectorboard.primitives.piece.PieceColor;
import net.models.challenge.ChallengeCreateResponse;
import net.models.challenge.mappers.ChallengeParamsMapper;
import net.models.challenge.mappers.StartedGameMapper;
import net.models.common.RestErrorCode;
import net.models.common.UserRefWithNickname;
import net.models.common.mappers.UserRefMapper;
import net.rest.Rest;
import net.rest.RestErrors;
import net.rest.RestOperationRegistry;

/** Presents the challenge creation overlay and carries out what it was filled in for: a challenge, or a game against a bot **/
class ChallengeCreationFlow
{
    /** `prefill` adjusts the draft the overlay opens with **/
    public static function present(?prefill:ChallengeDraft->Void):Void
    {
        var identity:Identity = IdentityKeeper.currentIdentity;
        ChallengeCreationOverlay.present(identity.isGuest(), identity.getUserRef(), create, prefill);
    }

    private static function create(params:ChallengeParams, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        var calleeRef:Null<String> = params.target.calleeRef();
        var onCreated:ChallengeCreateResponse->Void = onChallengeCreated.bind(_, onOutcome);
        var onFailed:HttpError->Void = onCreateFailed.bind(_, calleeRef != null, onOutcome);

        switch params.target
        {
            case Player(_) | Guest(_):
                Rest.client().execute(RestOperationRegistry.CREATE_DIRECT_CHALLENGE, onCreated, onFailed, null, null, ChallengeParamsMapper.datatypeToDirectDto(params, calleeRef));
            case Public | LinkOnly:
                Rest.client().execute(RestOperationRegistry.CREATE_OPEN_CHALLENGE, onCreated, onFailed, null, null, ChallengeParamsMapper.datatypeToOpenDto(params, params.target == LinkOnly));
            case Bot(settings):
                startBotGame(params, settings, onOutcome);
        }
    }

    private static function startBotGame(params:ChallengeParams, settings:BotSettings, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        var ownUserRef:Null<String> = IdentityKeeper.currentIdentity.getUserRef();
        if (ownUserRef == null)
        {
            onOutcome(Failed);
            return;
        }

        var userColor:PieceColor = params.callerColor ?? (Std.random(2) == 0 ? White : Black);
        Rest.client().execute(
            RestOperationRegistry.CREATE_EXTERNAL_GAME,
            game -> {
                GameRedirect.request(StartedGameMapper.summaryToDatatype(game, ownUserRef));
                onOutcome(GameStarted);
            },
            error -> {
                RequestFailureNotice.showHttpError(START_BOT_GAME, error);
                onOutcome(Failed);
            },
            null,
            null,
            ChallengeParamsMapper.datatypeToExternalGameDto(params, ownUserRef, userColor, BotRefs.build(settings.kind, settings.strength), settings.thinkCapSeconds)
        );
    }

    private static function onChallengeCreated(response:ChallengeCreateResponse, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        switch response.result
        {
            case MERGED:
                var ownUserRef:Null<String> = IdentityKeeper.currentIdentity.getUserRef();
                if (response.game != null && ownUserRef != null)
                    GameRedirect.request(StartedGameMapper.summaryToDatatype(response.game, ownUserRef));
                onOutcome(GameStarted);
            case CREATED:
                var callee:Null<UserRefWithNickname> = response.challenge?.callee;
                if (response.callee_online == false && callee != null)
                    CalleeOfflineNotice.show(UserRefMapper.displayName(callee), response.callee_session_lost == true);
                onOutcome(Created);
        }
    }

    private static function onCreateFailed(error:HttpError, direct:Bool, onOutcome:ChallengeCreationOutcome->Void):Void
    {
        if (direct && RestErrors.codeOf(error) == RestErrorCode.CALLEE_NOT_FOUND)
        {
            onOutcome(CalleeNotFound);
            return;
        }

        RequestFailureNotice.showHttpError(CREATE_CHALLENGE, error);
        onOutcome(Failed);
    }
}
