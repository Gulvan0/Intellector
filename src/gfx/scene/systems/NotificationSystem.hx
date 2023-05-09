package gfx.scene.systems;

import browser.Blinker;
import gfx.popups.IncomingChallengeDialog;
import net.INetObserver;
import gfx.popups.OpenChallengeCreated;
import assets.Audio;
import struct.ChallengeParams;
import net.shared.ServerEvent;

/**
    Responsible for Dialogs, Audio and Blinking
**/
class NotificationSystem implements INetObserver
{
    public function handleNetEvent(event:ServerEvent)
    {
        switch event
        {
            case CreateChallengeResult(Success(data)):
                var challengeParams:ChallengeParams = ChallengeParams.deserialize(data.serializedParams);
                switch challengeParams.type 
                {
                    case Public, ByLink:
                        Dialogs.getQueue().add(new OpenChallengeCreated(data.id));
                    case Direct(calleeLogin):
                        Dialogs.info(SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TEXT(calleeLogin), SEND_DIRECT_CHALLENGE_SUCCESS_DIALOG_TITLE, null, RemovedOnGameStarted);
                    default:
                }
                Audio.playSound("challenge_sent");
            case CreateChallengeResult(ToOneself):
                Dialogs.info(SEND_CHALLENGE_ERROR_TO_ONESELF, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(PlayerNotFound):
                Dialogs.info(SEND_CHALLENGE_ERROR_NOT_FOUND, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(AlreadyExists):
                Dialogs.info(SEND_CHALLENGE_ERROR_ALREADY_EXISTS, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(Duplicate):
                Dialogs.info(SEND_CHALLENGE_ERROR_DUPLICATE, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(RematchExpired):
                Dialogs.info(SEND_CHALLENGE_ERROR_REMATCH_EXPIRED, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(Impossible):
                Dialogs.info(SEND_CHALLENGE_ERROR_IMPOSSIBLE, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case CreateChallengeResult(ServerShutdown):
                Dialogs.info(SEND_CHALLENGE_ERROR_SERVER_SHUTDOWN, SEND_CHALLENGE_ERROR_DIALOG_TITLE, null, RemovedOnGameStarted);
            case ChallengeCancelledByOwner:
                Dialogs.info(INCOMING_CHALLENGE_ACCEPT_ERROR_CHALLENGE_CANCELLED, INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE);
            case ChallengeOwnerOffline(owner):
                Dialogs.info(INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_OFFLINE, INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE, [owner]);
            case ChallengeOwnerInGame(owner):
                Dialogs.info(INCOMING_CHALLENGE_ACCEPT_ERROR_CALLER_INGAME, INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE, [owner]);
            case ChallengeNotAcceptedServerShutdown:
                Dialogs.info(INCOMING_CHALLENGE_ACCEPT_ERROR_SERVER_SHUTDOWN, INCOMING_CHALLENGE_ACCEPT_ERROR_DIALOG_TITLE);
            case IncomingDirectChallenge(data):
                var scene:IPublicScene = SceneManager.getScene();
                if (!scene.isUserParticipatingInOngoingFiniteGame() && !Preferences.silentChallenges.get())
                {
                    Dialogs.getQueue().add(new IncomingChallengeDialog(data, scene.removeEntryFromChallengeList.bind(data.id)));
                    Blinker.blink(IncomingChallenge);
                    Audio.playSound("social");
                }
            default:
        }
    }  
    
    public function new()
    {

    }
}