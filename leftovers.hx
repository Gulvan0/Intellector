//! Chatbox.hx:

    public function handleNetEvent(event:ServerEvent) //To LiveGame.handleNetEvent
    {
        switch event
        {
            case Message(authorRef, message):
                appendMessage(authorRef, message, true);
            case SpectatorMessage(authorRef, message):
                if (ownerColor == null)
                    appendMessage(authorRef, message, false);
            case GameEnded(outcome, _, _, _): 
                onGameEnded(outcome);
            case PlayerDisconnected(color): 
                appendLog(Dictionary.getPhrase(PLAYER_DISCONNECTED_MESSAGE(color)));
            case PlayerReconnected(color): 
                appendLog(Dictionary.getPhrase(PLAYER_RECONNECTED_MESSAGE(color)));
            case NewSpectator(ref): 
                appendLog(Dictionary.getPhrase(SPECTATOR_JOINED_MESSAGE(Utils.playerRef(ref))));
            case SpectatorLeft(ref): 
                appendLog(Dictionary.getPhrase(SPECTATOR_LEFT_MESSAGE(Utils.playerRef(ref))));
            case DrawOffered(color):
                appendLog(Dictionary.getPhrase(DRAW_OFFERED_MESSAGE(color)));
            case DrawCancelled(color):
                appendLog(Dictionary.getPhrase(DRAW_CANCELLED_MESSAGE(color)));
            case DrawAccepted(color):
                appendLog(Dictionary.getPhrase(DRAW_ACCEPTED_MESSAGE(color)));
            case DrawDeclined(color):
                appendLog(Dictionary.getPhrase(DRAW_DECLINED_MESSAGE(color)));
            case TakebackOffered(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_OFFERED_MESSAGE(color)));
            case TakebackCancelled(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_CANCELLED_MESSAGE(color)));
            case TakebackAccepted(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_ACCEPTED_MESSAGE(color)));
            case TakebackDeclined(color):
                appendLog(Dictionary.getPhrase(TAKEBACK_DECLINED_MESSAGE(color)));
            case TimeAdded(color, _):
                appendLog(Dictionary.getPhrase(TIME_ADDED_MESSAGE(color)));
            default:
        }
    }

    public function reactToOwnAction(btn:ActionBtn) //To LiveGame.handleChatboxEvent
    {
        var message:Null<Phrase> = switch btn 
        {
            case OfferDraw: DRAW_OFFERED_MESSAGE(ownerColor);
            case CancelDraw: DRAW_CANCELLED_MESSAGE(ownerColor);
            case OfferTakeback: TAKEBACK_OFFERED_MESSAGE(ownerColor);
            case CancelTakeback: TAKEBACK_CANCELLED_MESSAGE(ownerColor);
            case AcceptDraw: DRAW_ACCEPTED_MESSAGE(ownerColor);
            case DeclineDraw: DRAW_DECLINED_MESSAGE(ownerColor);
            case AcceptTakeback: TAKEBACK_ACCEPTED_MESSAGE(ownerColor);
            case DeclineTakeback: TAKEBACK_DECLINED_MESSAGE(ownerColor);
            default: null;
        };
        if (message != null)
            appendLog(Dictionary.getPhrase(message));
    }

    //Also append game ended message (log)

    //For ChatboxEvent.Message handler
    Networker.emitEvent(MessageSent(text));
    if (ownerColor == null)
        appendMessage(ownRef, text, false);
    else 
        appendMessage(ownRef, text, true);