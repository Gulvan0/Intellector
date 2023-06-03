package gfx.screens;

import gfx.scene.Screen;
import gfx.ResponsiveToolbox.ResponsivenessRule;
import gfx.ResponsiveToolbox.ResponsiveProperty;
import net.shared.dataobj.ViewedScreen;
import dict.Phrase;
import assets.Paths;
import GlobalBroadcaster.IGlobalEventObserver;
import GlobalBroadcaster.GlobalEvent;
import net.shared.dataobj.ChallengeData;
import net.shared.TimeControlType;
import haxe.ui.tooltips.ToolTipManager;
import gfx.common.SituationTooltipRenderer;
import net.shared.dataobj.ChallengeParams;
import gfx.Dialogs;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import net.shared.TimeControl;
import net.shared.PieceColor;
import haxe.ui.components.Button;
import haxe.ui.styles.Style;
import haxe.ui.containers.VBox;
import dict.Dictionary;
import js.Browser;
import dict.Utils;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/simple_screens/join_challenge.xml'))
class OpenChallengeJoining extends Screen implements IGlobalEventObserver
{
    private final challengeID:Int;
    private final ratedChallenge:Bool;
    private final ownerLogin:String;
    
    private function onEnter()
    {
        GlobalBroadcaster.addObserver(this);
    }
    
    private function onClose()
    {
        GlobalBroadcaster.removeObserver(this);
    }

    public function getTitle():Null<Phrase>
    {
        return CHALLENGE_JOINING_SCREEN_TITLE(ownerLogin);
    }

    public function getURLPath():Null<String>
    {
        return 'join/$challengeID';
    }

    public function getPage():ViewedScreen
    {
        return Other;
    }

    private function getResponsiveComponents():Map<Component, Map<ResponsiveProperty, ResponsivenessRule>>
    {
        return [
            challengeByLabel => [StyleProp(FontSize) => VMIN(6)],
            challengeCard => [StyleProp(VerticalSpacing) => VMIN(1.75)],
            descriptionHBox => [StyleProp(HorizontalSpacing) => VMIN(2)],
            tcIconBox => [Width => VMIN(16), Height => VMIN(16)],
            tcLabel => [StyleProp(FontSize) => VMIN(4)],
            bracketLabel => [StyleProp(FontSize) => VMIN(4)],
            paramsBox => [StyleProp(HorizontalSpacing) => VMIN(1.5)],
            paramsLabel => [StyleProp(FontSize) => VMIN(4)],
            colorIcon => [Width => VMIN(4), Height => VMIN(4)],
            customStartPosIcon => [Width => VMIN(4), Height => VMIN(4)],
            acceptBtn => [StyleProp(FontSize) => VMIN(4.5)]
        ];
    }
    
    public function handleGlobalEvent(event:GlobalEvent)
    {
        switch event 
        {
            case LoggedIn, LoggedOut:
                refreshAcceptButton();
            default:
        }
    }

    private function canAccept():Bool
    {
        return !LoginManager.isPlayer(ownerLogin) && (LoginManager.isLogged() || !ratedChallenge);
    }

    private function refreshAcceptButton()
    {
        acceptBtn.disabled = !canAccept();
    }

    @:bind(acceptBtn, MouseEvent.CLICK)
    private function onAccepted(e)
    {
        if (canAccept())
            Networker.emitEvent(AcceptChallenge(challengeID));
    }

    private override function onReady()
    {
        super.onReady();
        if (tcIcon.originalWidth > tcIcon.originalHeight)
            tcIcon.percentWidth = 100;
        else
            tcIcon.percentHeight = 100;
    }

    public function new(data:ChallengeData)
    {
        super();

        this.challengeID = data.id;
        this.ownerLogin = data.ownerLogin;
        this.ratedChallenge = data.params.rated;

        var timeControlString:String = data.params.timeControl.toString();
        var timeControlType:TimeControlType = data.params.timeControl.getType();

        challengeByLabel.text = Dictionary.getPhrase(OPENJOIN_CHALLENGE_BY_HEADER, [data.ownerLogin]);

        tcIcon.resource = Paths.timeControl(timeControlType);
        tcLabel.text = timeControlString;
        if (timeControlType != Correspondence)
            tcLabel.text += ' (${Utils.getTimeControlTypeName(timeControlType)})';

        bracketLabel.text = Dictionary.getPhrase(data.params.rated? OPENJOIN_RATED : OPENJOIN_UNRATED);

        colorIcon.resource = Paths.challengeColor(data.params.acceptorColor);
        colorIcon.tooltip = switch data.params.acceptorColor {
            case White: Dictionary.getPhrase(OPENJOIN_COLOR_BLACK_OWNER, [data.ownerLogin]);
            case Black: Dictionary.getPhrase(OPENJOIN_COLOR_WHITE_OWNER, [data.ownerLogin]);
            case null: Dictionary.getPhrase(OPENJOIN_COLOR_RANDOM);
        };

        if (data.params.customStartingSituation != null)
        {
            customStartPosIcon.hidden = false;
            var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(data.params.customStartingSituation);
            ToolTipManager.instance.registerTooltip(customStartPosIcon, {
                renderer: renderer
            });
        }
        else
            customStartPosIcon.hidden = true;
        
        refreshAcceptButton();
    }
}