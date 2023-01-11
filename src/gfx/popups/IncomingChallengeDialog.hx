package gfx.popups;

import gfx.basic_components.BaseDialog;
import net.shared.dataobj.ChallengeData;
import haxe.ui.tooltips.ToolTipOptions;
import gfx.basic_components.AnnotatedImage;
import dict.Utils;
import net.shared.TimeControlType;
import haxe.ui.tooltips.ToolTipManager;
import gfx.common.SituationTooltipRenderer;
import assets.Paths;
import dict.Dictionary;
import utils.TimeControl;
import haxe.ui.events.MouseEvent;
import struct.ChallengeParams;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.core.Screen as HaxeUIScreen;

@:build(haxe.ui.macros.ComponentMacros.build('assets/layouts/popups/incoming_challenge_popup.xml'))
class IncomingChallengeDialog extends BaseDialog
{
    private var challengeID:Int;
    private var additionalCloseCallback:Void->Void;

    private function resize()
    {
        width = Math.min(350, HaxeUIScreen.instance.actualWidth * 0.98);
    }

    private function onClose(btn)
    {
        additionalCloseCallback();
    }

    @:bind(acceptBtn, MouseEvent.CLICK)
    private function onAccepted(e)
    {
        Networker.emitEvent(AcceptChallenge(challengeID));
        hideDialog(null);
    }

    @:bind(declineBtn, MouseEvent.CLICK)
    private function onDeclined(e)
    {
        Networker.emitEvent(DeclineDirectChallenge(challengeID));
        hideDialog(null);
    }

    public function new(data:ChallengeData, additionalCloseCallback:Void->Void)
    {
        super(RemovedOnGameStarted, false);

        this.closable = false;
        this.challengeID = data.id;
        this.additionalCloseCallback = additionalCloseCallback;

        var params:ChallengeParams = ChallengeParams.deserialize(data.serializedParams);
        
		challengeByLabel.text = Dictionary.getPhrase(INCOMING_CHALLENGE_CHALLENGE_BY_LABEL_TEXT, [data.ownerLogin]);
        challengeByLabel.setFontBold(true);
        
        var timeControlType:TimeControlType = params.timeControl.getType();
        var timeControlString:String = params.timeControl.toString();
        if (timeControlType != Correspondence)
            timeControlString += ' (${Utils.getTimeControlName(timeControlType)})';
        
        var timeControlRow:AnnotatedImage = new AnnotatedImage(Auto, Percent(100), Paths.timeControl(timeControlType), timeControlString, null, 0.08);
        timeControlRowBox.addComponent(timeControlRow);

		bracketLabel.text = Dictionary.getPhrase(params.rated? OPENJOIN_RATED : OPENJOIN_UNRATED);

		colorIcon.resource = Paths.challengeColor(params.acceptorColor);
        colorIcon.tooltip = switch params.acceptorColor 
        {
			case White: Dictionary.getPhrase(OPENJOIN_COLOR_BLACK_OWNER, [data.ownerLogin]);
			case Black: Dictionary.getPhrase(OPENJOIN_COLOR_WHITE_OWNER, [data.ownerLogin]);
			case null: Dictionary.getPhrase(OPENJOIN_COLOR_RANDOM);
		};

        if (params.customStartingSituation != null)
        {
            var renderer:SituationTooltipRenderer = new SituationTooltipRenderer(params.customStartingSituation);
            var tooltipOptions:ToolTipOptions = {renderer: renderer};
            ToolTipManager.instance.registerTooltip(customStartPosIcon, tooltipOptions);
        }
        else
            customStartPosIcon.hidden = true;
    }
}