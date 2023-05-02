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

//! Clock.hx:

    public function handleNetEvent(event:ServerEvent) //Move moveNum logic to LiveGame
    {
        if (!active)
            return;

        switch event 
        {
            case Move(_, timeData):
                if (timeData != null)
                    correctTime(timeData);
                moveNum++;
                toggleTurnColor();
            case Rollback(plysToUndo, timeData):
                correctTime(timeData);
                moveNum -= plysToUndo;
                if (plysToUndo % 2 == 1)
                    toggleTurnColor();
            case TimeAdded(_, timeData):
                correctTime(timeData);
            case GameEnded(_, _, remainingTimeMs, _):
                active = false;
                pauseTimer();
                if (remainingTimeMs != null)
                    label.text = TimeControl.secsToString(remainingTimeMs[ownerColor] / 1000);
                refreshColoring();
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        if (!active)
            return;

        switch event 
        {
            case ContinuationMove(_, _, _):
                moveNum++;
                toggleTurnColor();
            default:
        }
    }

//! PlyHistoryView.hx:

    //To screen logic (whether to update shownMovePointer of a model on ServerEvent.Move)
    public function handleNetEvent(event:ServerEvent)
    {
        switch event 
        {
            case Move(ply, _):
                var autoScrollEnabled:Bool = switch Preferences.autoScrollOnMove.get() 
                {
                    case Always: true;
                    case OwnGameOnly: isGamePlayable;
                    case Never: false;
                }
                var selectMove:Bool = shownMove == moveHistory.length || autoScrollEnabled;
                appendPly(ply, selectMove);
        }
    }

//! PositionEditor.hx

    //Hide position editor when it sends ApplyChangesRequested/DiscardChangesRequested event

//! ControlTabs.hx

    private function drawBranchingTab(initialVariant:Variant, ?selectedNode:VariantPath)
    {
        branchingTabType = Preferences.branchingTabType.get();
        switch branchingTabType
        {
            case Tree: 
                var tree:VariantTree = new VariantTree(initialVariant, selectedNode);
                variantView = tree;
                variantViewSV.hidden = false;
                variantViewSV.percentContentWidth = null;
                variantViewSV.addComponent(tree);
                variantViewSV.registerEvent(MouseEvent.MOUSE_WHEEL, onWheel.bind(tree), 100);
                onChange = e -> {
                    if (selectedPage == branchingTab)
                        tree.refreshLayout();
                };
                tree.refreshLayout();
            case Outline: 
                var comp:VariantOutline = new VariantOutline(initialVariant, selectedNode);
                variantView = comp;
                variantViewSV.hidden = true;
                variantViewSV.percentContentWidth = null;
                branchingTabContentsBox.addComponent(comp);
                onChange = e -> {
                    if (selectedPage == branchingTab)
                        comp.refreshSelection();
                };
            case PlainText: 
                var box:VariantPlainText = new VariantPlainText(initialVariant, selectedNode);
                variantView = box;
                variantViewSV.hidden = false;
                variantViewSV.percentContentWidth = 100;
                variantViewSV.addComponent(box);
                onChange = null;
        };
        variantView.init(eventHandler);
    }

//! Screen-related

    private static function getURLPath(type:ScreenType):Null<String>
    {
        return switch type 
        {
            case Analysis(_, _, exploredStudyData): exploredStudyData == null? "analysis" : 'study/${exploredStudyData.id}';
            case LiveGame(gameID, _): 'live/$gameID';
        }
    }

    private static function getPageByScreenInitializer(initializer:ScreenInitializer):ViewedScreen
    {
        return switch initializer 
        {
            case GameFromModelData(data, orientationPariticipantLogin): Game(data.gameID);
            case StartedGameVersusBot(params): Game(data.gameID);
            case NewAnalysisBoard: Analysis;
            case Study(info): Analysis;
            case AnalysisForLine(startingSituation, plys, viewedMovePointer): Analysis;
        }
    }