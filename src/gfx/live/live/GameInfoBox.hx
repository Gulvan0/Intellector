package gfx.live.live;

import net.shared.utils.UnixTimestamp;
import gfx.live.interfaces.IReadOnlyGameRelatedModel;
import net.shared.openings.OpeningDatabase;
import net.shared.openings.Opening;
import GlobalBroadcaster.IGlobalEventObserver;
import haxe.ui.core.Component;
import gfx.live.events.ModelUpdateEvent;
import gfx.live.interfaces.IGameScreen;
import gfx.live.models.ReadOnlyModel;
import gfx.live.interfaces.IGameComponent;
import net.shared.board.Situation;
import net.shared.board.RawPly;
import utils.SpecialChar;
import net.shared.EloValue;
import GlobalBroadcaster.GlobalEvent;
import gfx.profile.simple_components.PlayerLabel;
import net.shared.TimeControlType;
import dict.Utils;
import assets.Paths;
import net.INetObserver;
import net.shared.ServerEvent;
import utils.TimeControl;
import haxe.ui.containers.Card;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import net.shared.PieceType;
import net.shared.PieceColor;
import haxe.ui.styles.Style;
import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import net.shared.Outcome;

using gfx.live.models.CommonModelExtractors;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/live/gameinfobox.xml'))
class GameInfoBox extends Card implements IGameComponent implements IGlobalEventObserver
{
    private var whitePlayerLabel:PlayerLabel;
    private var crossSign:Label;
    private var blackPlayerLabel:PlayerLabel;

    private var renderedForWidth:Float = 0;

    public function init(model:ReadOnlyModel, gameScreen:IGameScreen)
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        GlobalBroadcaster.addObserver(this);

        var tcType:TimeControlType = gameModel.getTimeControl().getType();

        var separator:String = " " + SpecialChar.Dot + " ";
        if (tcType == Correspondence)
            matchParameters.text = Dictionary.getPhrase(CORRESPONDENCE_TIME_CONTROL_NAME);
        else
            matchParameters.text = gameModel.getTimeControl().toString() + separator + tcType.getName();

        var whiteRef = gameModel.getPlayerRef(White);
        var blackRef = gameModel.getPlayerRef(Black);
        var whiteELO = gameModel.getELO(White);
        var blackELO = gameModel.getELO(Black);

        whitePlayerLabel = new PlayerLabel(Exact(20), whiteRef, whiteELO, true);
        whitePlayerLabel.horizontalAlign = "center";

        crossSign = new Label();
        crossSign.text = "⚔";
        crossSign.customStyle = {fontSize: 20, fontBold: true, horizontalAlign: "center"};

        blackPlayerLabel = new PlayerLabel(Exact(20), blackRef, blackELO, true);
        blackPlayerLabel.horizontalAlign = "center";

        opponentsBox.addComponent(whitePlayerLabel);
        opponentsBox.addComponent(crossSign);
        opponentsBox.addComponent(blackPlayerLabel);
        
        resolution.text = Utils.getResolution(gameModel.getOutcome());
        timeControlIcon.resource = Paths.timeControl(tcType);

        var startTimestamp:UnixTimestamp = gameModel.getStartTimestamp();
        if (startTimestamp != null)
            datetime.text = startTimestamp.format(DotDelimitedDayWithSeparateTime);
        else
            datetime.text = Dictionary.getPhrase(OLD_GAME_DATETIME);

        updateOpeningLabel(gameModel, !model.match(Spectation(_)));

        if (FollowManager.isFollowing())
            markFollowedPlayer(gameModel.getColorByRef(FollowManager.getFollowedPlayerLogin()));
    }

    public function handleModelUpdate(model:ReadOnlyModel, event:ModelUpdateEvent)
    {
        var gameModel:IReadOnlyGameRelatedModel = model.asGameModel();

        switch event 
        {
            case ShownSituationUpdated:
                updateOpeningLabel(gameModel, !model.match(Spectation(_)));
            case GameEnded:
                resolution.text = Utils.getResolution(gameModel.getOutcome());
                updateOpeningLabel(gameModel, !model.match(Spectation(_)));
            default:
        }
    }

    private function updateOpeningLabel(gameModel:IReadOnlyGameRelatedModel, hideRealName:Bool)
    {
        var pointer:Int = gameModel.getShownMovePointer();

        if (pointer == 0)
        {
            var startingSituation:Situation = gameModel.getStartingSituation();

            if (startingSituation.isDefaultStarting())
                openingLabel.text = Dictionary.getPhrase(OPENING_STARTING_POSITION);
            else
            {
                var sip:String = startingSituation.serialize();
                var opening:Null<Opening> = OpeningDatabase.get(sip);

                if (opening != null)
                    openingLabel.text = opening.renderName(hideRealName);
                else
                    openingLabel.text = Dictionary.getPhrase(OPENING_UNORTHODOX_STARTING_POSITION);
            }
        }
        else
        {
            var line = gameModel.getLine().slice(0, pointer);
            var i = line.length - 1;

            while (i >= 0)
            {
                var sip:String = line[i].situationAfter.serialize();
                var opening:Null<Opening> = OpeningDatabase.get(sip);

                if (opening != null)
                {
                    openingLabel.text = opening.renderName(hideRealName);
                    return;
                }

                i--;
            }

            openingLabel.text = Dictionary.getPhrase(OPENING_UNORTHODOX_LINE);
        }
    }

    public function destroy()
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function asComponent():Component
    {
        return this;
    }

    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case FollowedPlayerUpdated(followedLogin):
                if (followedLogin == null)
                    markFollowedPlayer(null);
                else if (whitePlayerLabel.playerRef == followedLogin.toLowerCase())
                    markFollowedPlayer(White);
                else if (blackPlayerLabel.playerRef == followedLogin.toLowerCase())
                    markFollowedPlayer(Black);
                else
                    markFollowedPlayer(null);
            default:
        }
    }

    private override function validateComponentLayout():Bool 
    {
        var b = super.validateComponentLayout();

        if (renderedForWidth == this.width)
            return b;

        var thisStyle = this.customStyle.clone();
        thisStyle.verticalSpacing = this.width / 70;
        thisStyle.padding = this.width * 15 / 350;
        this.customStyle = thisStyle;

        var mpStyle = matchParameters.customStyle.clone();
        mpStyle.fontSize = this.width * 16 / 350;
        matchParameters.customStyle = mpStyle;

        var dtStyle = datetime.customStyle.clone();
        dtStyle.fontSize = this.width * 12 / 350;
        datetime.customStyle = dtStyle;

        var resStyle = resolution.customStyle.clone();
        resStyle.fontSize = this.width / 25;
        resolution.customStyle = resStyle;

        imagebox.width = this.width / 5;
        imagebox.height = this.width / 5;
        ResponsiveToolbox.fitComponent(timeControlIcon);

        var oppStyle = opponentsBox.customStyle.clone();
        oppStyle.marginLeft = this.width / 70;
        opponentsBox.customStyle = oppStyle;

        var wlStyle = whitePlayerLabel.customStyle.clone();
        wlStyle.fontSize = this.width * 17 / 350;
        whitePlayerLabel.customStyle = wlStyle;

        var crossStyle = crossSign.customStyle.clone();
        crossStyle.fontSize = this.width * 20 / 350;
        crossSign.customStyle = crossStyle;

        var blStyle = blackPlayerLabel.customStyle.clone();
        blStyle.fontSize = this.width * 17 / 350;
        blackPlayerLabel.customStyle = blStyle;

        var opStyle = openingLabel.customStyle.clone();
        opStyle.fontSize = this.width / 25;
        opStyle.marginTop = this.width / 35;
        openingLabel.customStyle = opStyle;

        renderedForWidth = this.width;
        return b;
    }

    private function markFollowedPlayer(color:Null<PieceColor>)
    {
        switch color 
        {
            case null:
                watchingLabel.hidden = true;
            case White:
                watchingLabel.hidden = false;
                watchingLabel.text = Dictionary.getPhrase(LIVE_WATCHING_LABEL_TEXT(Utils.playerRef(whitePlayerLabel.playerRef)));
            case Black:
                watchingLabel.hidden = false;
                watchingLabel.text = Dictionary.getPhrase(LIVE_WATCHING_LABEL_TEXT(Utils.playerRef(blackPlayerLabel.playerRef)));
        }
    }

    public function new() 
    {
        super();
    }
}