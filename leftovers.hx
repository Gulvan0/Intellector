//! ???

//Don't forget - LiveGame should listen to premovesEnabled preference updates. Handler should refresh model's boardInteractivityMode and emit InteractivityModeUpdated event
//Don't forget - LiveGame should broadcast global events (InGame - entered when participant, NotInGame - left when participant & game ended when participant)

//! Chatbox.hx:

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

//! Analysis.hx, whole

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/analysis/analysis_layout.xml'))
class Analysis extends Screen implements IGameBoardObserver implements IGlobalEventObserver
{
    private var variant:Variant;

    private var board:GameBoard;
    private var positionEditor:PositionEditor;
    private var controlTabs:ControlTabs;

    private var analysisPeripheryObservers:Array<IAnalysisPeripheralEventObserver>;
    private var gameboardObservers:Array<IGameBoardObserver>;
    private var plyHistoryViews:Array<PlyHistoryView>;

    public function onEnter()
    {
        GlobalBroadcaster.addObserver(this);
    }

    public function onClose()
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        board.handleGlobalEvent(event);

        switch event 
        {
            case LoggedIn:
                actionBar.playFromPosBtn.disabled = false;
            case LoggedOut:
                actionBar.playFromPosBtn.disabled = true;
            case PreferenceUpdated(Marking):
                boardContainer.invalidateComponentLayout(true);
            case PreferenceUpdated(BranchingType):
                controlTabs.redrawBranchingTab(variant);
            case PreferenceUpdated(BranchingShowTurnColor):
                if (controlTabs.branchingTabType == Tree)
                    controlTabs.redrawBranchingTab(variant);
            default:
        }
    }

    private function redrawPositionEditor()
    {
        positionEditor.updateLayout(positionEditorContainer.width, HaxeUIScreen.instance.actualHeight * 0.3);
    }

    private override function validateComponentLayout():Bool 
    {
        var compact:Bool = HaxeUIScreen.instance.actualWidth / HaxeUIScreen.instance.actualHeight < 1.2;
        var wasCompact:Bool = lControlTabsContainer.hidden;

        cCreepingLineContainer.hidden = !compact;
        cActionBarContainer.hidden = !compact;
        lControlTabsContainer.hidden = compact;

        var parentChanged:Bool = super.validateComponentLayout();

        Timer.delay(redrawPositionEditor, 100);

        return parentChanged || wasCompact != compact;
    }

    private function displayShareDialog()
    {
        var shareDialog:ShareDialog = new ShareDialog();
        switch SceneManager.getCurrentScreenType()
        {
            case Analysis(_, _, exploredStudyData):
                shareDialog.initInAnalysis(board.shownSituation, board.orientationColor, variant, exploredStudyData); //TODO: Use model property
            default:
                throw "ShareRequested happened outside of Analysis screen!";
        }
        
        shareDialog.showShareDialog(board);
    }

    private function handlePeripheralEvent(event:PeripheralEvent)
    {
        if (!Networker.isConnectedToServer() && event.match(PlayFromHereRequested))
            return;

        for (obs in analysisPeripheryObservers)
            obs.handleAnalysisPeripheralEvent(event);

        if (event.match(ShareRequested))
            displayShareDialog();
        else if (event.match(PlayFromHereRequested))
            Dialogs.getQueue().add(new ChallengeParamsDialog(ChallengeParams.playFromPosParams(board.shownSituation), true));
        else if (event.match(ApplyChangesRequested))
        {
            for (view in plyHistoryViews)
                view.updateStartingSituation(board.startingSituation);
            controlTabs.clearBranching(board.startingSituation);
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        for (obs in gameboardObservers)
            obs.handleGameBoardEvent(event);
    }

    private override function onReady()
    {
        super.onReady();
        if (positionEditor.isReady)
            redrawPositionEditor();
        else
            positionEditor.customReadyHandler = redrawPositionEditor;
    }

    public function new(?initialVariantStr:String, ?selectedMainlineMove:Int)
    {
        super();
        customEnterHandler = onEnter;
        customCloseHandler = onClose;

        variant = initialVariantStr != null? Variant.deserialize(initialVariantStr) : new Variant(Situation.defaultStarting());

        board = new GameBoard(Analysis(variant));
        board.percentHeight = 100;
        board.percentWidth = 100;

        controlTabs = new ControlTabs(variant, handlePeripheralEvent);
        positionEditor = new PositionEditor(handlePeripheralEvent);
        positionEditor.hidden = true;

        analysisPeripheryObservers = [board, controlTabs, controlTabs.navigator, positionEditor, creepingLine, actionBar];
        gameboardObservers = [controlTabs, controlTabs.navigator, positionEditor, creepingLine];
        plyHistoryViews = [controlTabs.navigator, creepingLine];

        for (view in plyHistoryViews)
            view.init(type -> {handlePeripheralEvent(ScrollBtnPressed(type));}, Analysis(variant));

        actionBar.init(true, handlePeripheralEvent);

        boardContainer.addComponent(board);
        lControlTabsContainer.addComponent(controlTabs);
        positionEditorContainer.addComponent(positionEditor);

        board.addObserver(this);

        if (selectedMainlineMove != null)
            handlePeripheralEvent(ScrollBtnPressed(Precise(selectedMainlineMove)));
    }
}

//! LiveGame.hx, whole

@:build(haxe.ui.macros.ComponentMacros.build("assets/layouts/live/live_layout.xml"))
class LiveGame extends Screen implements INetObserver implements IGameBoardObserver implements IGlobalEventObserver
{
    private var board:GameBoard;
    
    /**Attains null if a user doesn't participate in the game (is a spectator or browses a past game)**/
    private var playerColor:Null<PieceColor>;
    private var orientationColor:PieceColor = White;

    private var isPastGame:Bool;
    private var botOpponent:Null<Bot> = null;
    private var gameID:Int;
    private var whiteRef:PlayerRef;
    private var blackRef:PlayerRef;
    private var timeControl:TimeControl;
    private var datetime:Date;
    private var outcome:Null<Outcome> = null;
    private var rated:Bool;
    private var getSecsLeftAfterMove:Null<(side:PieceColor, plyNum:Int)->Null<Float>>;

    private var netObservers:Array<INetObserver>;
    private var gameboardObservers:Array<IGameBoardObserver>;

    public static var MIN_SIDEBARS_WIDTH:Float = 250;
    public static var MAX_SIDEBARS_WIDTH:Float = 350;

    public function onEnter()
    {
        GlobalBroadcaster.addObserver(this); //TO SCREENS THAT NEED IT
        Audio.playSound("notify"); //TO SCREENS THAT NEED IT
    }

    public function onClose()
    {
        if (botOpponent != null)
            botOpponent.interrupt(); //TO BOT SCREEN

        if (FollowManager.followedGameID == gameID)
            FollowManager.stopFollowing(); //TO SPEC SCREEN

        GlobalBroadcaster.removeObserver(this); //TO SCREENS THAT NEED IT
    }

    private function performValidation() 
    {
        var availableWidth:Float = HaxeUIScreen.instance.actualWidth;
        var availableHeight:Float = HaxeUIScreen.instance.actualHeight * 0.95;

        var compact:Bool = availableWidth / availableHeight < 1.3;
        var compactBoardHeight:Float = availableWidth * BoardSize.inverseAspectRatio(board.lettersEnabled);
        var largeBoardMaxWidth:Float = availableHeight / BoardSize.inverseAspectRatio(board.lettersEnabled);
        var bothBarsVisible:Bool = availableWidth >= largeBoardMaxWidth + 2 * MIN_SIDEBARS_WIDTH;

        cBlackPlayerHBox.hidden = !compact;
        cWhitePlayerHBox.hidden = !compact;
        cActionBar.hidden = !compact;
        cCreepingLine.hidden = !compact;
        cSpacer1.hidden = !compact;
        cSpacer2.hidden = !compact;

        lLeftBox.hidden = compact || !bothBarsVisible;
        lRightBox.hidden = compact;
        
        if (compact)
        {
            boardContainer.percentHeight = null;
            boardContainer.height = Math.min(compactBoardHeight + 10, availableHeight - cCreepingLine.height - cActionBar.height - cBlackPlayerHBox.height - cWhitePlayerHBox.height - 45);
        }
        else
        {
            boardContainer.height = null;
            boardContainer.percentHeight = 100;
        }

        if (bothBarsVisible)
        {
            lLeftBox.width = Math.min(MAX_SIDEBARS_WIDTH, (availableWidth - largeBoardMaxWidth) / 2);
            lRightBox.width = Math.min(MAX_SIDEBARS_WIDTH, (availableWidth - largeBoardMaxWidth) / 2);
        }
        else
        {
            lLeftBox.width = 20;
            lRightBox.width = MathUtils.clamp(availableWidth - largeBoardMaxWidth, MIN_SIDEBARS_WIDTH, MAX_SIDEBARS_WIDTH);
        }
    }

    //================================================================================================================================================================

    private function onRematchRequested()
    {
        var opponentRef:PlayerRef = playerColor == White? blackRef : whiteRef;

        switch opponentRef.concretize() 
        {
            case Normal(login):
                var params:ChallengeParams = ChallengeParams.rematchParams(login, playerColor, timeControl, rated, board.startingSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Bot(handle):
                var params:ChallengeParams = ChallengeParams.botRematchParams(handle, playerColor, timeControl, rated, board.startingSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Guest(_):
                Networker.emitEvent(SimpleRematch);
        }
    }
    
    private function onContinuationMovePlayed(ply:RawPly)
    {
        if (botOpponent != null)
        {
            var reaction:Null<Phrase> = botOpponent.getReactionToMove(ply, board.currentSituation);
            if (reaction != null)
                botchat.appendBotMessage(botOpponent.name, Dictionary.getPhrase(reaction));
        }
        
        Networker.emitEvent(Move(ply));
    }

    private function makeBotMove(timeData:TimeReservesData)
    {
        var botTimeData:Null<BotTimeData> = null;
        if (!timeControl.isCorrespondence())
        {
            var moveNum:Int = board.plyHistory.length() + 1;
            var secsLeft:Float = timeData.getSecsLeftNow(board.currentSituation.turnColor, Date.now().getTime(), moveNum >= 3);
            botTimeData = new BotTimeData(secsLeft, timeControl.bonusSecs, moveNum, playerColor == Black);
        }

        var onBotMessage:Phrase->Void = phrase -> {
            botchat.appendBotMessage(botOpponent.name, Dictionary.getPhrase(phrase));
        };
        var onMoveChosen:RawPly->Void = ply -> {
            Networker.emitEvent(Move(ply));
            handleNetEvent(Move(ply, null));
        };
        
        botOpponent.playMove(board.currentSituation, botTimeData, onBotMessage, onMoveChosen);
    }

    //=================================================================================================================================================================

    public function handleNetEvent(event:ServerEvent)
    {
        for (obs in netObservers)
            obs.handleNetEvent(event);

        switch event 
        {
            case BotMove(timeData):
                makeBotMove(timeData);
            case GameEnded(outcome, _, _, newPersonalElo):
                Audio.playSound("notify");
                this.outcome = outcome;

                var message:String;
                if (playerColor != null)
                    message = Utils.getPlayerGameOverDialogMessage(outcome, playerColor, newPersonalElo);
                else
                    message = Utils.getSpectatorGameOverDialogMessage(outcome, whiteRef, blackRef);
                
                Dialogs.infoRaw(message, Dictionary.getPhrase(GAME_ENDED_DIALOG_TITLE));
            default:
        }
    }

    public function handleGameBoardEvent(event:GameBoardEvent)
    {
        for (obs in gameboardObservers)
            obs.handleGameBoardEvent(event);

        switch event 
        {
            case ContinuationMove(ply, _, _):
                onContinuationMovePlayed(ply);
            default:
        }
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        board.handleGlobalEvent(event);
        gameinfobox.handleGlobalEvent(event);

        switch event 
        {
            case LoggedIn:
                cActionBar.playFromPosBtn.disabled = false;
                lActionBar.playFromPosBtn.disabled = false;
            case LoggedOut:
                cActionBar.playFromPosBtn.disabled = true;
                lActionBar.playFromPosBtn.disabled = true;
            case PreferenceUpdated(Marking):
                boardContainer.invalidateComponentLayout(true);
            default:
        }
        
    }

    private function onPlyScrollRequested(type:PlyScrollType)
    {
        cCreepingLine.performScroll(type);
        lNavigator.performScroll(type);
        board.applyScrolling(type);
        if (getSecsLeftAfterMove != null)
        {
            cWhiteClock.setTimeManually(getSecsLeftAfterMove(White, lNavigator.shownMove));
            cBlackClock.setTimeManually(getSecsLeftAfterMove(Black, lNavigator.shownMove));
            lWhiteClock.setTimeManually(getSecsLeftAfterMove(White, lNavigator.shownMove));
            lBlackClock.setTimeManually(getSecsLeftAfterMove(Black, lNavigator.shownMove));
        }
    }

    public function handleActionBtnPress(btn:ActionBtn)
    {
        switch btn 
        {
            case Resign:
                if (botOpponent != null)
                    botOpponent.interrupt();
                Networker.emitEvent(Resign);
            case ChangeOrientation:
                setOrientation(opposite(orientationColor));
            case OfferDraw:
                Networker.emitEvent(OfferDraw);
            case CancelDraw:
                Networker.emitEvent(CancelDraw);
            case OfferTakeback:
                if (botOpponent != null)
                    botOpponent.interrupt();
                Networker.emitEvent(OfferTakeback);
            case CancelTakeback:
                Networker.emitEvent(CancelTakeback);
            case AddTime:
                Networker.emitEvent(AddTime);
            case Rematch:
                onRematchRequested();
            case Share:
                var gameLink:String = Url.getGameLink(gameID);
                var playedMoves:Array<RawPly> = board.plyHistory.getPlySequence();
                var pin:String = PortableIntellectorNotation.serialize(board.startingSituation, playedMoves, whiteRef, blackRef, timeControl, datetime, outcome);

                var shareDialog:ShareDialog = new ShareDialog();
                shareDialog.initInGame(board.shownSituation, board.orientationColor, gameLink, pin, board.startingSituation, playedMoves);
                shareDialog.showShareDialog(board);
            case PlayFromHere:
                var params:ChallengeParams = ChallengeParams.playFromPosParams(board.shownSituation);
                Dialogs.getQueue().add(new ChallengeParamsDialog(params, true));
            case Analyze:
                SceneManager.toScreen(Analysis(getSerializedVariant(), board.plyHistory.pointer, null));
            case AcceptDraw:
                Networker.emitEvent(AcceptDraw);
            case DeclineDraw:
                Networker.emitEvent(DeclineDraw);
            case AcceptTakeback:
                Networker.emitEvent(AcceptTakeback);
            case DeclineTakeback:
                Networker.emitEvent(DeclineTakeback);
            case PrevMove:
                onPlyScrollRequested(Prev);
            case NextMove:
                onPlyScrollRequested(Next);
        }
        chatbox.reactToOwnAction(btn);
    }

    private function getSerializedVariant():String
    {
        var variant:Variant = new Variant(board.startingSituation);

        var path:Array<Int> = [];
        for (ply in board.plyHistory.getPlySequence())
        {
            variant.addChildToNode(ply, path);
            path.push(0);
        }

        return variant.serialize();
	}

    //================================================================================================================================================================

    private function setOrientation(newOrientationColor:PieceColor)
    {
        if (orientationColor == newOrientationColor)
            return;

        board.setOrientation(newOrientationColor);

        orientationColor = newOrientationColor;

        //Compact bars

        centerBox.removeComponent(cWhitePlayerHBox, false);
        centerBox.removeComponent(cBlackPlayerHBox, false);

        var upperBox:HBox = orientationColor == White? cBlackPlayerHBox : cWhitePlayerHBox;
        var lowerBox:HBox = orientationColor == White? cWhitePlayerHBox : cBlackPlayerHBox;

        centerBox.addComponentAt(upperBox, 2);
        centerBox.addComponentAt(lowerBox, 4);

        //Large cards & clocks

        lRightBox.removeComponent(lWhiteClock, false);
        lRightBox.removeComponent(lBlackClock, false);
        lRightBox.removeComponent(lWhiteLoginCard, false);
        lRightBox.removeComponent(lBlackLoginCard, false);

        var upperClock:Clock = newOrientationColor == White? lBlackClock : lWhiteClock;
        var bottomClock:Clock = newOrientationColor == White? lWhiteClock : lBlackClock;
        var upperLogin:Card = newOrientationColor == White? lBlackLoginCard : lWhiteLoginCard;
        var bottomLogin:Card = newOrientationColor == White? lWhiteLoginCard : lBlackLoginCard;

        lRightBox.addComponentAt(upperLogin, 0);
        lRightBox.addComponentAt(upperClock, 0);

        lRightBox.addComponent(bottomLogin);
        lRightBox.addComponent(bottomClock);
    }

    public function new(gameID:Int, constructor:LiveGameConstructor) 
    {
        super();

        board = new GameBoard(Live(constructor));
        chatbox.init(constructor);
        gameinfobox.init(constructor);

        this.gameID = gameID;
        this.netObservers = [gameinfobox, chatbox, lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock, board]; //Board should ALWAYS be the last observer in order for premoves to work correctly. Maybe someday I'll fix that, but atm it's troublesome
        this.gameboardObservers = [lActionBar, lNavigator, lBlackClock, lWhiteClock, cActionBar, cCreepingLine, cBlackClock, cWhiteClock];

        customEnterHandler = onEnter;
        customCloseHandler = onClose;
        
        cWhiteClock.resize(30);
        cBlackClock.resize(30);

        var ongoingTimeData:Option<TimeReservesData> = None;

        switch constructor 
        {
            case New(whiteRef, blackRef, playerElos, timeControl, _, startDatetime):
                this.isPastGame = false;
                this.playerColor = LoginManager.isPlayer(blackRef)? Black : White;
                this.whiteRef = whiteRef;
                this.blackRef = blackRef;
                this.timeControl = timeControl;
                this.datetime = startDatetime;
                this.outcome = null;
                this.rated = playerElos != null;
                this.getSecsLeftAfterMove = null;

                setOrientation(playerColor);

            case Ongoing(parsedData, timeData, followedPlayerLogin):
                ongoingTimeData = Some(timeData);

                this.isPastGame = false;
                this.playerColor = parsedData.getPlayerColor();
                this.whiteRef = parsedData.whiteRef;
                this.blackRef = parsedData.blackRef;
                this.timeControl = parsedData.timeControl;
                this.datetime = parsedData.datetime;
                this.outcome = parsedData.outcome;
                this.rated = parsedData.isRated();
                this.getSecsLeftAfterMove = null;

                if (followedPlayerLogin != null)
                    setOrientation(parsedData.getParticipantColor(followedPlayerLogin));
                else if (playerColor != null)
                    setOrientation(playerColor);
                else
                    setOrientation(White);

            case Past(parsedData, watchedPlyerLogin):
                this.isPastGame = true;
                this.playerColor = null;
                this.whiteRef = parsedData.whiteRef;
                this.blackRef = parsedData.blackRef;
                this.timeControl = parsedData.timeControl;
                this.datetime = parsedData.datetime;
                this.outcome = parsedData.outcome;
                this.rated = parsedData.isRated();
                this.getSecsLeftAfterMove = parsedData.msPerMoveDataAvailable? parsedData.getSecsLeftAfterMove : null;

                setOrientation(watchedPlyerLogin != null? parsedData.getParticipantColor(watchedPlyerLogin) : White);
        }

        board.addObserver(this);

        board.horizontalAlign = 'center';
        board.verticalAlign = 'center';
        board.percentHeight = 100;
        board.percentWidth = 100;

        boardContainer.percentHeight = 100;
        boardContainer.addComponent(board);

        var opponentRef:PlayerRef = playerColor == White? blackRef : whiteRef;
        switch opponentRef.concretize() 
        {
            case Bot(botHandle):
                if (!isPastGame)
                {
                    botOpponent = BotFactory.build(botHandle);
                    switch ongoingTimeData 
                    {
                        case Some(v):
                            makeBotMove(v);
                        default:
                    }
                }
                chatstack.selectedIndex = 1;
            default:
                chatstack.selectedIndex = 0;
        }

        cWhiteLoginLabel.text = lWhiteLoginLabel.text = Utils.playerRef(whiteRef);
        cBlackLoginLabel.text = lBlackLoginLabel.text = Utils.playerRef(blackRef);

        cWhiteClock.init(constructor, White);
        cBlackClock.init(constructor, Black);
        lWhiteClock.init(constructor, White);
        lBlackClock.init(constructor, Black);

        lNavigator.init(onPlyScrollRequested, Live(constructor));
        lActionBar.init(constructor, false, handleActionBtnPress);
        cCreepingLine.init(onPlyScrollRequested, Live(constructor));
        cActionBar.init(constructor, true, handleActionBtnPress);
    }
}