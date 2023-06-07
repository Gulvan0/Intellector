package gfx.game.live;

import gfx.game.interfaces.IGameScreenGetters;
import net.shared.PieceColor.opposite;
import gfx.game.common.action_bar.ActionButton;
import GlobalBroadcaster.IGlobalEventObserver;
import GlobalBroadcaster.GlobalEvent;
import gfx.game.interfaces.IReadOnlyGameRelatedModel;
import gfx.game.events.ModelUpdateEvent;
import gfx.game.interfaces.IBehaviour;
import gfx.game.models.ReadOnlyModel;
import gfx.game.interfaces.IGameComponent;
import gfx.game.common.action_bar.ActionBar;

using gfx.game.models.CommonModelExtractors;

class LiveActionBar extends ActionBar implements IGameComponent implements IGlobalEventObserver
{
    //TODO: Compact: request box hides action buttons on appearance - removed behaviour - test if it needs to be reintroduced!

    private final compact:Bool;

    public function init(model:ReadOnlyModel, getters:IGameScreenGetters):Void
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        var buttonSets:Array<Array<ActionButton>> = [];

        switch model 
        {
            case MatchVersusPlayer(model):
                var activeDrawOfferButton:ActionButton = OfferDraw;
                var activeTakebackOfferButton:ActionButton = OfferTakeback;

                if (model.isOutgoingOfferActive(gameModel.getPlayerColor(), Draw))
                    activeDrawOfferButton = CancelDraw;

                if (model.isOutgoingOfferActive(gameModel.getPlayerColor(), Takeback))
                    activeTakebackOfferButton = CancelTakeback;

                if (model.isOutgoingOfferActive(opposite(gameModel.getPlayerColor()), Draw))
                {
                    setBtnDisabled(OfferDraw, true);
                    displayRequestBox(Draw);
                }

                if (model.isOutgoingOfferActive(opposite(gameModel.getPlayerColor()), Takeback))
                {
                    setBtnDisabled(OfferTakeback, true);
                    displayRequestBox(Takeback);
                }

                if (model.hasEnded())
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, Rematch, PlayFromHere, Analyze, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, Rematch, PlayFromHere, Analyze, Share]
                        ];
                    }
                }
                else if (model.getTimeControl().isCorrespondence())
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, activeDrawOfferButton, activeTakebackOfferButton, Resign, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, activeDrawOfferButton, activeTakebackOfferButton, Resign, Share]
                        ];
                    }
                } 
                else
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, activeDrawOfferButton, activeTakebackOfferButton, AddTime, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Resign, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, activeDrawOfferButton, activeTakebackOfferButton, Resign, AddTime, Share]
                        ];
                    }
                }

            case MatchVersusBot(model):
                if (model.hasEnded())
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, Rematch, PlayFromHere, Analyze, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, Rematch, PlayFromHere, Analyze, Share]
                        ];
                    }
                }
                else if (model.getTimeControl().isCorrespondence())
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, OfferTakeback, Resign, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, OfferTakeback, Resign, Share]
                        ];
                    }
                } 
                else
                {
                    if (compact)
                    {
                        buttonSets = [
                            [ChangeOrientation, OfferTakeback, Resign, AddTime, PrevMove, NextMove],
                            [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                        ];
                    }
                    else
                    {
                        buttonSets = [
                            [ChangeOrientation, OfferTakeback, Resign, AddTime, Share]
                        ];
                    }
                }

            case Spectation(model):
                if (compact)
                {
                    buttonSets = [
                        [ChangeOrientation, PlayFromHere, Analyze, PrevMove, NextMove],
                        [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                    ];
                }
                else
                {
                    buttonSets = [
                        [ChangeOrientation, PlayFromHere, Analyze, Share]
                    ];
                }
                
            case AnalysisBoard(_):
                throw "LiveActionBar can't be used in Analysis";
        }

        updateButtonSets(buttonSets);
        onMoveCountUpdated(gameModel.getLineLength(), gameModel.getStartingSituation().turnColor == gameModel.getPlayerColor());

        if (!LoginManager.isLogged())
        {
            setBtnDisabled(Rematch, true);
            setBtnDisabled(PlayFromHere, true);
        }

        if (gameModel.getTimeControl().isCorrespondence())
            setBtnDisabled(AddTime, true);

        eventHandler = getters.getBehaviour().handleActionBarEvent;
        GlobalBroadcaster.addObserver(this);
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent):Void
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        switch event 
        {
            case GameEnded:
                if (compact)
                {
                    updateButtonSets([
                        [ChangeOrientation, Rematch, PlayFromHere, Analyze, PrevMove, NextMove],
                        [OpenChat, OpenGameInfo, OpenSpecialControlSettings, Share]
                    ]);
                }
                else
                {
                    updateButtonSets([
                        [ChangeOrientation, Rematch, PlayFromHere, Analyze, Share]
                    ]);
                }
                
                hideRequestBox(Draw);
                hideRequestBox(Takeback);
            case OfferStateUpdated(kind, Incoming, active):
                setBtnDisabled(kind == Draw? OfferDraw : OfferTakeback, active);
                if (active)
                    displayRequestBox(kind);
                else
                    hideRequestBox(kind);
            case OfferStateUpdated(Draw, Outgoing, true):
                replaceButton(OfferDraw, CancelDraw);
            case OfferStateUpdated(Takeback, Outgoing, true):
                replaceButton(OfferTakeback, CancelTakeback);
            case OfferStateUpdated(Draw, Outgoing, false):
                replaceButton(CancelDraw, OfferDraw);
            case OfferStateUpdated(Takeback, Outgoing, false):
                replaceButton(CancelTakeback, OfferTakeback);
            case MoveAddedToHistory | HistoryRollback:
                onMoveCountUpdated(gameModel.getLineLength(), gameModel.getStartingSituation().turnColor == gameModel.getPlayerColor());
            default:
        }
    }

    public function destroy():Void
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn:
                setBtnDisabled(PlayFromHere, false);
            case LoggedOut:
                setBtnDisabled(PlayFromHere, true);
            default:
        }
    }

    private function onMoveCountUpdated(moveCnt:Int, playerMovesFirst:Bool)
    {
        setBtnDisabled(OfferDraw, moveCnt < 2);
        setBtnDisabled(OfferTakeback, playerMovesFirst? moveCnt < 1 : moveCnt < 2);
        if (moveCnt < 2)
            replaceButton(Abort, Resign);
        else
            replaceButton(Resign, Abort);
    }

    public function new(compact:Bool)
    {
        super();
        this.compact = compact;
    }
}