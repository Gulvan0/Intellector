package net;

import net.EventProcessingQueue.INetObserver;
import openfl.Assets;
import dict.Utils;
import dict.Dictionary;
import gfx.components.Dialogs;

class GeneralObserver implements INetObserver
{
    public static var acceptsDirectChallenges:Bool = true;

    private function onReconnectionForbidden() 
    {
        Networker.doNotReconnect = true;
        Dialogs.alert("Session closed", "Alert");
    }

    private static function challengeReceiver(caller:String, startSecs:Int, bonusSecs:Int, color:String) 
    {
        Assets.getSound("sounds/social.mp3").play();

        var onConfirmed = Networker.emitEvent.bind(AcceptDirectChallenge(caller));
        var onDeclined = Networker.emitEvent.bind(DeclineDirectChallenge(caller));

        var detailsStr = Utils.challengeDetails(startSecs, bonusSecs, color);
        var title = Dictionary.getPhrase(INCOMING_CHALLENGE_TITLE);
        var text = Dictionary.getPhrase(INCOMING_CHALLENGE_TEXT, [caller, detailsStr]);

        Dialogs.confirm(text, title, onConfirmed, onDeclined);
    }

    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case IncomingDirectChallenge(enemy, colour, startSecs, bonusSecs):
                if (acceptsDirectChallenges)
                    challengeReceiver(enemy, startSecs, bonusSecs, colour);
            case DontReconnect:
                onReconnectionForbidden();
            case DirectChallengeCalleeIsCaller(callee):
                Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SAME), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeCalleeOffline(callee):
                Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_OFFLINE), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeCalleeNotFound(callee):
                Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_NOTFOUND), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeCalleeInGame(callee):
                Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_BUSY), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeRepeated(callee):
                Dialogs.alert(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_REPEATED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeSent(callee):
                Assets.getSound("sounds/challenge_sent.mp3").play();
                Dialogs.info(Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS) + '$callee!', Dictionary.getPhrase(SEND_CHALLENGE_RESULT_SUCCESS_TITLE));
            case DirectChallengeDeclined(callee):
                Dialogs.info('$callee' + Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_DECLINED_TITLE));
            case DirectChallengeWasCancelled(callee):
                Dialogs.alert(Dictionary.getPhrase(ACCEPT_CHALLENGE_RESULT_CANCELLED), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeCallerOffline(caller):
                Dialogs.alert(Dictionary.getPhrase(ACCEPT_CHALLENGE_RESULT_OFFLINE), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            case DirectChallengeCallerInGame(caller):
                Dialogs.alert(Dictionary.getPhrase(ACCEPT_CHALLENGE_RESULT_BUSY), Dictionary.getPhrase(SEND_CHALLENGE_RESULT_ERROR_TITLE));
            default:
        }
    }

    public function new()
    {

    }
}