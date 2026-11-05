package client.ui.common.challenges;

import client.auth.Identity;
import client.datatypes.challenge.ChallengeMarks;
import client.datatypes.challenge.IncomingChallenge;
import client.datatypes.challenge.OutgoingChallenge;
import client.datatypes.game.StartedGame;
import client.datatypes.request.FailedAction;
import client.storage.ChallengeMarksStorage;
import client.tabs.GameRedirect;
import client.ui.common.challenges.widget.ChallengesWidget;
import client.ui.common.notifications.RequestFailureNotice;
import easypubsub.Subscription;
import haxefolio.HaxeFolioApp;
import http.HttpError;
import net.models.challenge.mappers.IncomingChallengeMapper;
import net.models.challenge.mappers.OutgoingChallengeMapper;
import net.models.challenge.mappers.StartedGameMapper;
import net.rest.Rest;
import net.rest.RestOperationRegistry;
import net.ws.PubSub;
import net.ws.channels.IncomingChallenges;
import net.ws.channels.OutgoingChallenges;
import net.ws.events.IncomingChallengeAccepted;
import net.ws.events.IncomingChallengeCancelled;
import net.ws.events.IncomingChallengeDeclined;
import net.ws.events.IncomingChallengeReceived;
import net.ws.events.IncomingChallengesCancelledByServer;
import net.ws.events.IncomingChallengesRefresh;
import net.ws.events.OutgoingChallengeAccepted;
import net.ws.events.OutgoingChallengeCancelled;
import net.ws.events.OutgoingChallengeCreated;
import net.ws.events.OutgoingChallengeRejected;
import net.ws.events.OutgoingChallengesCancelledByServer;
import net.ws.events.OutgoingChallengesRefresh;

/** The user's pending challenges: feeds them to the `ChallengesController` from the server, and sends its replies to the server **/
class ChallengeFlows
{
    private final challenges:ChallengesController;

    private var incomingSubscription:Null<Subscription<IncomingChallenges>> = null;
    private var outgoingSubscription:Null<Subscription<OutgoingChallenges>> = null;
    private var userRef:Null<String> = null;

    public function new(widget:ChallengesWidget)
    {
        challenges = new ChallengesController(widget, accept, decline, cancel, saveMarks);
        ChallengeMarksStorage.addExternalChangeHandler(() -> userRef, challenges.applyMarks);
    }

    /** Starts following the challenges of the new identity instead of the previous one's **/
    public function onIdentityChanged(identity:Identity):Void
    {
        if (incomingSubscription != null)
        {
            incomingSubscription.detach();
            incomingSubscription = null;
        }

        if (outgoingSubscription != null)
        {
            outgoingSubscription.detach();
            outgoingSubscription = null;
        }

        userRef = null;
        challenges.reset();

        var newUserRef:Null<String> = identity.getUserRef();
        if (newUserRef == null)
            return;

        userRef = newUserRef;
        challenges.applyMarks(ChallengeMarksStorage.read(newUserRef));

        incomingSubscription = PubSub.sub(new IncomingChallenges(newUserRef))
            .onEventLight(IncomingChallengesRefresh, refresh -> challenges.syncIncoming(refresh.challenges.map(IncomingChallengeMapper.dtoToDatatype)))
            .onEventLight(IncomingChallengeReceived, challenge -> challenges.receiveIncoming(IncomingChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(IncomingChallengeCancelled, cancelled -> challenges.removeIncoming(cancelled.id))
            .onEventLight(IncomingChallengeAccepted, accepted -> challenges.removeIncoming(accepted.id))
            .onEventLight(IncomingChallengeDeclined, declined -> challenges.removeIncoming(declined.id))
            .onEventLight(IncomingChallengesCancelledByServer, cancelled -> {
                for (id in cancelled.ids)
                    challenges.removeIncoming(id);
            });

        outgoingSubscription = PubSub.sub(new OutgoingChallenges(newUserRef))
            .onEventLight(OutgoingChallengesRefresh, refresh -> onOutgoingRefresh(refresh.challenges.map(OutgoingChallengeMapper.dtoToDatatype)))
            .onEventLight(OutgoingChallengeCreated, challenge -> challenges.addOutgoing(OutgoingChallengeMapper.dtoToDatatype(challenge)))
            .onEventLight(OutgoingChallengeCancelled, cancelled -> challenges.removeOutgoing(cancelled.id))
            .onEventLight(OutgoingChallengeAccepted, accepted -> onOutgoingAccepted(accepted.id))
            .onEventLight(OutgoingChallengeRejected, rejected -> challenges.removeOutgoing(rejected.id))
            .onEventLight(OutgoingChallengesCancelledByServer, cancelled -> {
                for (id in cancelled.ids)
                    challenges.removeOutgoing(id);
            });
    }

    private function saveMarks(marks:ChallengeMarks):Void
    {
        if (userRef != null)
            ChallengeMarksStorage.save(userRef, marks);
    }

    // a challenge missing from a refresh may have been accepted while disconnected
    private function onOutgoingRefresh(pending:Array<OutgoingChallenge>):Void
    {
        for (dropped in challenges.syncOutgoing(pending))
            redirectToResultingGame(dropped.id);
    }

    private function onOutgoingAccepted(challengeId:Int):Void
    {
        challenges.removeOutgoing(challengeId);
        redirectToResultingGame(challengeId);
    }

    private function redirectToResultingGame(challengeId:Int):Void
    {
        Rest.client().execute(
            RestOperationRegistry.GET_CHALLENGE,
            challenge -> {
                var game:Null<StartedGame> = StartedGameMapper.resultingGameToDatatype(challenge);
                if (game != null)
                    GameRedirect.request(game);
            },
            RequestFailureNotice.showHttpError.bind(OPEN_STARTED_GAME),
            ["challenge_id" => Std.string(challengeId)]
        );
    }

    private function accept(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.ACCEPT_CHALLENGE,
            game -> {
                challenges.acceptSucceeded();
                HaxeFolioApp.navigateTo('live/${game.id}');
            },
            onAcceptFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    private function onAcceptFailed(challenge:IncomingChallenge, error:HttpError):Void
    {
        challenges.acceptFailed(challenge.id);

        if (isResolved(error))
        {
            challenges.removeIncoming(challenge.id);
            RequestFailureNotice.show(ACCEPT_CHALLENGE, ChallengeUnavailable);
        }
        else
            RequestFailureNotice.showHttpError(ACCEPT_CHALLENGE, error);
    }

    private function decline(challenge:IncomingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.DECLINE_CHALLENGE,
            _ -> {},
            onDeclineFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // already off display: put back unless the challenge is gone anyway
    private function onDeclineFailed(challenge:IncomingChallenge, error:HttpError):Void
    {
        if (isResolved(error))
            return;

        challenges.declineFailed(challenge);
        RequestFailureNotice.showHttpError(DECLINE_CHALLENGE, error);
    }

    private function cancel(challenge:OutgoingChallenge):Void
    {
        Rest.client().execute(
            RestOperationRegistry.CANCEL_CHALLENGE,
            _ -> {},
            onCancelFailed.bind(challenge),
            ["challenge_id" => Std.string(challenge.id)]
        );
    }

    // already off display: put back unless the challenge is gone anyway
    private function onCancelFailed(challenge:OutgoingChallenge, error:HttpError):Void
    {
        if (isResolved(error))
            return;

        challenges.cancelFailed(challenge);
        RequestFailureNotice.showHttpError(CANCEL_CHALLENGE, error);
    }

    // not found, or no longer active: cancelled, accepted or declined already
    private function isResolved(error:HttpError):Bool
    {
        return error.httpStatus == 404 || error.httpStatus == 422;
    }
}
